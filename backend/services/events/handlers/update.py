import json
import boto3
import os
from shared.utils import build_response, get_logger
from services.events.models import build_update_expression

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME'))

def lambda_handler(event, context):
    logger = get_logger(context)
    
    try:
        event_id = event.get('pathParameters', {}).get('eventId')
        if not event_id:
            logger.warning("Event ID missing")
            return build_response(400, {'error': 'Event ID path parameter is required'})
            
        body = json.loads(event.get('body', '{}'))
        if not body:
            return build_response(400, {'error': 'No fields provided for update'})
            
        logger.info(f"Processing update for event {event_id}")
            
        resp = table.get_item(Key={'PK': f"EVENT#{event_id}", 'SK': 'METADATA'})
        if 'Item' not in resp:
            return build_response(404, {'error': 'Event not found'})

        update_expr, expr_attr_names, expr_attr_values, error = build_update_expression(body)
        if error:
            return build_response(400, {'error': error})
        
        response = table.update_item(
            Key={'PK': f"EVENT#{event_id}", 'SK': 'METADATA'},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_attr_names,
            ExpressionAttributeValues=expr_attr_values,
            ReturnValues="ALL_NEW"
        )
        
        logger.info(f"Successfully updated event {event_id}")
        return build_response(200, {'message': 'Event updated', 'event': response.get('Attributes')})
        
    except Exception as e:
        logger.error(f"Unhandled exception: {str(e)}", exc_info=True)
        return build_response(500, {'error': 'Internal server error'})
