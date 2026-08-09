import json
import boto3
import os
from shared.utils import build_response, get_logger
from services.events.models import validate_create_payload, build_event_item

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME'))

def lambda_handler(event, context):
    logger = get_logger(context)
    logger.info("Processing create event request")
    
    try:
        body = json.loads(event.get('body', '{}'))
        ok, error = validate_create_payload(body)
        if not ok:
            logger.warning("Missing required fields")
            return build_response(400, {'error': error})

        item = build_event_item(body)

        try:
            table.put_item(
                Item=item,
                ConditionExpression="attribute_not_exists(PK)"
            )
            logger.info(f"Successfully created event {body['eventId']}")
            return build_response(201, {'message': 'Event created successfully', 'event': item})
        except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
            logger.warning(f"Event {body['eventId']} already exists")
            return build_response(409, {'error': 'Event already exists'})

    except Exception as e:
        logger.error(f"Unhandled exception: {str(e)}", exc_info=True)
        return build_response(500, {'error': 'Internal server error'})
