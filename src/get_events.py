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
        # Querying the table for all items where the SK is 'METADATA'
        # Since we are using single-table design, this isolates the actual event details
        # away from the registration items.
        response = table.scan(
            FilterExpression=Key('SK').eq('METADATA')
        )
        
        events = response.get('Items', [])
        
        return build_response(200, {'events': events})

    except Exception as e:
        print(f"Error: {str(e)}")
        return build_response(500, {'error': 'Internal server error'})