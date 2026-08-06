import json
import boto3
import os
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns') # Added SNS Client

table_name = os.environ.get('TABLE_NAME')
sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
table = dynamodb.Table(table_name)

def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(body)
    }

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        event_id = body.get('eventId')
        email = body.get('email')

        # Input Validation (Phase 4 Requirement)
        if not event_id or not email:
            return build_response(400, {'error': 'eventId and email are required'})
        if "@" not in email:
            return build_response(400, {'error': 'Invalid email format'})

        registration_id = str(uuid.uuid4())
        
        # Write to DynamoDB
        table.put_item(
            Item={
                'PK': f"EVENT#{event_id}",
                'SK': f"REG#{email}",
                'UserEmail': email,
                'RegistrationId': registration_id,
                'RegistrationDate': datetime.utcnow().isoformat()
            }
        )

        # Publish Confirmation to SNS
        if sns_topic_arn:
            message = f"Success! You are registered for Event ID: {event_id}.\nYour Registration Ticket ID is: {registration_id}"
            sns.publish(
                TopicArn=sns_topic_arn,
                Subject="Event Registration Confirmed!",
                Message=message
            )

        return build_response(201, {
            'message': 'Successfully registered',
            'registrationId': registration_id
        })

    except Exception as e:
        print(f"Error: {str(e)}")
        return build_response(500, {'error': 'Internal server error'})