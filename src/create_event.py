import json
import boto3
import os
from shared import build_response, get_logger

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME'))

def lambda_handler(event, context):
    logger = get_logger(context)
    logger.info("Processing create event request")
    
    try:
        body = json.loads(event.get('body', '{}'))
        event_id = body.get('eventId')
        event_name = body.get('eventName')
        date = body.get('date')
        
        if not event_id or not event_name or not date:
            logger.warning("Missing required fields")
            return build_response(400, {'error': 'eventId, eventName, and date are required'})
            
        # Optional fields
        venue = body.get('venue', '')
        description = body.get('description', '')
        max_capacity = body.get('maxCapacity')
        status = body.get('status', 'Available')
        
        item = {
            'PK': f"EVENT#{event_id}",
            'SK': 'METADATA',
            'EventId': event_id,
            'EventName': event_name,
            'Date': date,
            'Venue': venue,
            'Description': description,
            'Status': status
        }
        if max_capacity is not None:
            item['MaxCapacity'] = max_capacity
            
        try:
            table.put_item(
                Item=item,
                ConditionExpression="attribute_not_exists(PK)"
            )
            logger.info(f"Successfully created event {event_id}")
            return build_response(201, {'message': 'Event created successfully', 'event': item})
        except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
            logger.warning(f"Event {event_id} already exists")
            return build_response(409, {'error': 'Event already exists'})

    except Exception as e:
        logger.error(f"Unhandled exception: {str(e)}", exc_info=True)
        return build_response(500, {'error': 'Internal server error'})
