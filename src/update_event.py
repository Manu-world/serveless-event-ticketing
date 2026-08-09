import json
import boto3
import os
from shared import build_response, get_logger

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
            
        # Verify event exists first
        resp = table.get_item(Key={'PK': f"EVENT#{event_id}", 'SK': 'METADATA'})
        if 'Item' not in resp:
            return build_response(404, {'error': 'Event not found'})
            
        update_expr = "SET "
        expr_attr_values = {}
        expr_attr_names = {}
        
        # Mapping frontend fields to DB fields
        field_map = {
            'eventName': 'EventName',
            'date': 'Date',
            'venue': 'Venue',
            'description': 'Description',
            'status': 'Status',
            'maxCapacity': 'MaxCapacity'
        }
        
        updates = []
        for body_key, db_key in field_map.items():
            if body_key in body:
                attr_name = f"#{db_key}"
                attr_val = f":{db_key}"
                updates.append(f"{attr_name} = {attr_val}")
                expr_attr_names[attr_name] = db_key
                expr_attr_values[attr_val] = body[body_key]
                
        if not updates:
            return build_response(400, {'error': 'No valid fields provided for update'})
            
        update_expr += ", ".join(updates)
        
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
