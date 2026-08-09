import json
from services.events.handlers.update import lambda_handler

def test_update_event_missing_id(api_gateway_event, lambda_context):
    response = lambda_handler(api_gateway_event(body=json.dumps({'eventName': 'A'})), lambda_context)
    assert response['statusCode'] == 400

def test_update_event_not_found(mock_dynamodb, api_gateway_event, lambda_context):
    event = api_gateway_event(body=json.dumps({'eventName': 'A'}), path_parameters={'eventId': 'evt1'})
    response = lambda_handler(event, lambda_context)
    assert response['statusCode'] == 404

def test_update_event_success(mock_dynamodb, api_gateway_event, lambda_context):
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'METADATA', 'EventId': 'evt1', 'EventName': 'Old'})
    
    event = api_gateway_event(body=json.dumps({'eventName': 'New'}), path_parameters={'eventId': 'evt1'})
    response = lambda_handler(event, lambda_context)
    assert response['statusCode'] == 200
    
    item = mock_dynamodb.get_item(Key={'PK': 'EVENT#evt1', 'SK': 'METADATA'})['Item']
    assert item['EventName'] == 'New'
