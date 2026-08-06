import json
import boto3
import os
from decimal import Decimal
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME'))

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super().default(obj)

def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }

def lambda_handler(event, context):
    try:
        # Extract the email from the URL path parameters
        email = event['pathParameters']['email']
        
        # Query the GSI to find all events for this user
        response = table.query(
            IndexName='UserEmailIndex',
            KeyConditionExpression=Key('UserEmail').eq(email)
        )
        
        return build_response(200, {'registrations': response.get('Items', [])})

    except KeyError:
        return build_response(400, {'error': 'Email path parameter is missing'})
    except Exception as e:
        print(f"Error: {str(e)}")
        return build_response(500, {'error': 'Internal server error'})
