import json
from services.events.handlers.delete import lambda_handler

def test_delete_event_missing_id(api_gateway_event, lambda_context):
    response = lambda_handler(api_gateway_event(), lambda_context)
    assert response['statusCode'] == 400

def test_delete_event_not_found(mock_dynamodb, api_gateway_event, lambda_context):
    event = api_gateway_event(path_parameters={'eventId': 'evt1'})
    response = lambda_handler(event, lambda_context)
    assert response['statusCode'] == 404

def test_delete_event_with_registrations(mock_dynamodb, api_gateway_event, lambda_context):
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'METADATA', 'EventId': 'evt1'})
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'REG#u@e.com'})
    
    event = api_gateway_event(path_parameters={'eventId': 'evt1'})
    response = lambda_handler(event, lambda_context)
    assert response['statusCode'] == 409
    assert json.loads(response['body'])['activeRegistrations'] == 1

def test_delete_event_success(mock_dynamodb, api_gateway_event, lambda_context):
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'METADATA', 'EventId': 'evt1'})
    
    event = api_gateway_event(path_parameters={'eventId': 'evt1'})
    response = lambda_handler(event, lambda_context)
    assert response['statusCode'] == 200
    
    items = mock_dynamodb.scan()['Items']
    assert len(items) == 0
