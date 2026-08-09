import json
from create_event import lambda_handler

def test_create_event_missing_fields(api_gateway_event, lambda_context):
    response = lambda_handler(api_gateway_event(body=json.dumps({})), lambda_context)
    assert response['statusCode'] == 400

def test_create_event_success(mock_dynamodb, api_gateway_event, lambda_context):
    body = {
        'eventId': 'evt1',
        'eventName': 'Concert',
        'date': '2025-01-01',
        'venue': 'Arena'
    }
    response = lambda_handler(api_gateway_event(body=json.dumps(body)), lambda_context)
    assert response['statusCode'] == 201
    
    items = mock_dynamodb.scan()['Items']
    assert len(items) == 1
    assert items[0]['EventName'] == 'Concert'
    assert items[0]['SK'] == 'METADATA'

def test_create_event_duplicate(mock_dynamodb, api_gateway_event, lambda_context):
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'METADATA', 'EventId': 'evt1'})
    
    body = {'eventId': 'evt1', 'eventName': 'Concert', 'date': '2025-01-01'}
    response = lambda_handler(api_gateway_event(body=json.dumps(body)), lambda_context)
    assert response['statusCode'] == 409
