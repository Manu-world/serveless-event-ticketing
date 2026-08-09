import boto3
import os
from boto3.dynamodb.conditions import Key
from shared.utils import build_response, get_logger, validate_email

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME'))

def lambda_handler(event, context):
    logger = get_logger(context)
    
    try:
        email = event.get('pathParameters', {}).get('email')
        
        if not email:
            logger.warning("Email path parameter is missing")
            return build_response(400, {'error': 'Email path parameter is missing'})
            
        if not validate_email(email):
            logger.warning(f"Invalid email format: {email}")
            return build_response(400, {'error': 'Invalid email format'})
            
        logger.info(f"Fetching registrations for {email}")
        
        response = table.query(
            IndexName='UserEmailIndex',
            KeyConditionExpression=Key('UserEmail').eq(email)
        )
        
        registrations = response.get('Items', [])
        logger.info(f"Retrieved {len(registrations)} registrations for {email}")
        
        return build_response(200, {'registrations': registrations})

    except Exception as e:
        logger.error(f"Error fetching registrations: {str(e)}", exc_info=True)
        return build_response(500, {'error': 'Internal server error'})
