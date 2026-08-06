import json
import boto3
import os

# Using the client interface here for precise key mapping
dynamodb = boto3.client('dynamodb')
table_name = os.environ.get('TABLE_NAME')

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
        registration_id = event['pathParameters']['id']
        
        # 1. Find the Primary Key and Sort Key associated with this RegistrationId
        response = dynamodb.scan(
            TableName=table_name,
            FilterExpression="RegistrationId = :rid",
            ExpressionAttributeValues={":rid": {"S": registration_id}}
        )
        
        items = response.get('Items', [])
        if not items:
            return build_response(404, {'error': 'Registration not found'})
        
        # 2. Extract the exact keys
        item_to_delete = items[0]
        pk = item_to_delete['PK']['S']
        sk = item_to_delete['SK']['S']
        
        # 3. Execute the deletion
        dynamodb.delete_item(
            TableName=table_name,
            Key={'PK': {'S': pk}, 'SK': {'S': sk}}
        )
        
        return build_response(200, {'message': f'Registration {registration_id} cancelled successfully'})

    except KeyError:
        return build_response(400, {'error': 'Registration ID path parameter is missing'})
    except Exception as e:
        print(f"Error: {str(e)}")
        return build_response(500, {'error': 'Internal server error'})
