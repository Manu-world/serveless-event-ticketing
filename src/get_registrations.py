import json
import boto3
import os
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME'))

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
