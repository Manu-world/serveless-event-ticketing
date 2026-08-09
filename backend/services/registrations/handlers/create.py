import json
import boto3
import os
import uuid
from datetime import datetime, timezone
from shared.utils import build_response, get_logger, validate_email
from shared.email_service import EmailService

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME')
table = dynamodb.Table(table_name)

# We still publish to SNS for ADMIN alerts, as requested in architecture
sns = boto3.client('sns')
sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    logger = get_logger(context)
    logger.info("Processing registration request")
    
    try:
        body = json.loads(event.get('body', '{}'))
        event_id = body.get('eventId')
        email = body.get('email')

        if not event_id or not email:
            logger.warning("Missing eventId or email")
            return build_response(400, {'error': 'eventId and email are required'})
            
        if not validate_email(email):
            logger.warning(f"Invalid email format: {email}")
            return build_response(400, {'error': 'Invalid email format'})

        # Verify event exists
        try:
            event_resp = table.get_item(Key={'PK': f"EVENT#{event_id}", 'SK': 'METADATA'})
            if 'Item' not in event_resp:
                logger.warning(f"Event not found: {event_id}")
                return build_response(404, {'error': 'Event not found'})
        except Exception as e:
            logger.error(f"Error checking event existence: {str(e)}")
            return build_response(500, {'error': 'Internal server error'})

        registration_id = str(uuid.uuid4())
        
        # Write to DynamoDB with condition to prevent duplicates
        try:
            table.put_item(
                Item={
                    'PK': f"EVENT#{event_id}",
                    'SK': f"REG#{email}",
                    'UserEmail': email,
                    'RegistrationId': registration_id,
                    'RegistrationDate': datetime.now(timezone.utc).isoformat()
                },
                ConditionExpression="attribute_not_exists(PK) AND attribute_not_exists(SK)"
            )
            logger.info(f"Successfully created registration {registration_id} for {email}")
        except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
            logger.info(f"Duplicate registration attempt for {email} on {event_id}")
            # Fetch existing registration id to return it
            try:
                existing_resp = table.get_item(Key={'PK': f"EVENT#{event_id}", 'SK': f"REG#{email}"})
                if 'Item' in existing_resp:
                    existing_id = existing_resp['Item'].get('RegistrationId')
                    return build_response(200, {
                        'message': 'Already registered',
                        'registrationId': existing_id
                    })
            except Exception as e:
                logger.error(f"Error fetching existing registration: {str(e)}")
                return build_response(500, {'error': 'Internal server error'})
            
            return build_response(409, {'error': 'Registration already exists'})

        # Send user confirmation email
        email_svc = EmailService(logger)
        email_svc.send_confirmation(email, event_id, registration_id)

        # Admin alert via SNS
        if sns_topic_arn:
            try:
                sns.publish(
                    TopicArn=sns_topic_arn,
                    Subject="New Event Registration",
                    Message=f"New registration for {event_id} by {email}."
                )
            except Exception as e:
                logger.error(f"Failed to publish admin alert to SNS: {str(e)}")

        return build_response(201, {
            'message': 'Successfully registered',
            'registrationId': registration_id
        })

    except Exception as e:
        logger.error(f"Unhandled exception: {str(e)}", exc_info=True)
        return build_response(500, {'error': 'Internal server error'})