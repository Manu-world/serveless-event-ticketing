import json
import boto3
import os
import uuid
from datetime import datetime

# Initialize outside the handler for warm-start performance
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME')
table = dynamodb.Table(table_name)

def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Access-Control-Allow-Origin': '*', # Critical for full-stack integration
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

        if not event_id or not email:
            return build_response(400, {'error': 'eventId and email are required'})

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

        return build_response(201, {
            'message': 'Successfully registered',
            'registrationId': registration_id
        })

    except Exception as e:
        print(f"Error: {str(e)}") # Automatically picked up by CloudWatch Logs
        return build_response(500, {'error': 'Internal server error'})