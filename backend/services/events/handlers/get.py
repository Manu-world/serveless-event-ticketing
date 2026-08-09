import boto3
import os
from boto3.dynamodb.conditions import Key
from shared.utils import build_response, get_logger

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME'))

def lambda_handler(event, context):
    logger = get_logger(context)
    logger.info("Fetching events")
    
    try:
        # Use SKIndex to avoid table scan
        response = table.query(
            IndexName='SKIndex',
            KeyConditionExpression=Key('SK').eq('METADATA')
        )
        
        events = response.get('Items', [])
        logger.info(f"Retrieved {len(events)} events")
        
        return build_response(200, {'events': events})

    except Exception as e:
        logger.error(f"Error fetching events: {str(e)}", exc_info=True)
        return build_response(500, {'error': 'Internal server error'})