import boto3
import os
from boto3.dynamodb.conditions import Key
from shared import build_response, get_logger, validate_uuid

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    logger = get_logger(context)
    
    try:
        registration_id = event.get('pathParameters', {}).get('id')
        
        if not registration_id:
            logger.warning("Registration ID path parameter is missing")
            return build_response(400, {'error': 'Registration ID path parameter is missing'})
            
        if not validate_uuid(registration_id):
            logger.warning(f"Invalid UUID format for registration id: {registration_id}")
            return build_response(400, {'error': 'Invalid Registration ID format'})
            
        logger.info(f"Attempting to delete registration {registration_id}")
        
        # 1. Query the GSI to find PK/SK
        response = table.query(
            IndexName='RegistrationIdIndex',
            KeyConditionExpression=Key('RegistrationId').eq(registration_id)
        )
        
        items = response.get('Items', [])
        if not items:
            logger.info(f"Registration {registration_id} not found")
            return build_response(404, {'error': 'Registration not found'})
            
        item_to_delete = items[0]
        pk = item_to_delete['PK']
        sk = item_to_delete['SK']
        
        # 2. Execute the deletion using resource interface
        table.delete_item(
            Key={'PK': pk, 'SK': sk}
        )
        
        logger.info(f"Successfully deleted registration {registration_id}")
        return build_response(200, {'message': f'Registration {registration_id} cancelled successfully'})

    except Exception as e:
        logger.error(f"Error deleting registration: {str(e)}", exc_info=True)
        return build_response(500, {'error': 'Internal server error'})
