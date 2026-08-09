import json
import logging
import re
import uuid
from decimal import Decimal

# Configure structured JSON logging
class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_record = {
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
            "aws_request_id": getattr(record, 'aws_request_id', 'N/A')
        }
        if record.exc_info:
            log_record["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_record)

def get_logger(context):
    logger = logging.getLogger(context.function_name if hasattr(context, 'function_name') else 'local')
    logger.setLevel(logging.INFO)
    
    # Remove existing handlers to avoid duplicates in Lambda
    if logger.handlers:
        logger.handlers.clear()
        
    handler = logging.StreamHandler()
    handler.setFormatter(JSONFormatter())
    logger.addHandler(handler)
    
    # Inject aws_request_id into the logger instance for convenience
    logger = logging.LoggerAdapter(logger, {'aws_request_id': getattr(context, 'aws_request_id', 'N/A')})
    return logger

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super().default(obj)

def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Access-Control-Allow-Origin': '*', # Handled safely via API GW configuration
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }

def validate_email(email):
    # Basic robust email regex
    pattern = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
    return re.match(pattern, email) is not None

def validate_uuid(value):
    try:
        uuid.UUID(str(value))
        return True
    except ValueError:
        return False
