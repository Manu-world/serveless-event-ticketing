import boto3
import os
from boto3.dynamodb.conditions import Key
from shared.utils import build_response, get_logger

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME'))

def lambda_handler(event, context):
    logger = get_logger(context)
    
    try:
        event_id = event.get('pathParameters', {}).get('eventId')
        if not event_id:
            logger.warning("Event ID missing")
            return build_response(400, {'error': 'Event ID path parameter is required'})
            
        logger.info(f"Processing delete for event {event_id}")
            
        pk = f"EVENT#{event_id}"
        
        # Check if event exists
        resp = table.get_item(Key={'PK': pk, 'SK': 'METADATA'})
        if 'Item' not in resp:
            return build_response(404, {'error': 'Event not found'})
            
        # Check for active registrations
        regs_resp = table.query(
            KeyConditionExpression=Key('PK').eq(pk) & Key('SK').begins_with('REG#')
        )
        
        if regs_resp.get('Items'):
            count = len(regs_resp.get('Items'))
            logger.warning(f"Cannot delete event {event_id}. Has {count} active registrations.")
            return build_response(409, {
                'error': 'Cannot delete event with active registrations', 
                'activeRegistrations': count
            })
            
        table.delete_item(Key={'PK': pk, 'SK': 'METADATA'})
        logger.info(f"Successfully deleted event {event_id}")
        
        return build_response(200, {'message': 'Event deleted successfully'})
        
    except Exception as e:
        logger.error(f"Unhandled exception: {str(e)}", exc_info=True)
        return build_response(500, {'error': 'Internal server error'})
