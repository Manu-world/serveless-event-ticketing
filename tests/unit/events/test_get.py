import json
from services.events.handlers.get import lambda_handler

def test_get_events_empty(mock_dynamodb, api_gateway_event, lambda_context):
    response = lambda_handler(api_gateway_event(), lambda_context)
    assert response['statusCode'] == 200
    assert json.loads(response['body'])['events'] == []

def test_get_events_success(mock_dynamodb, api_gateway_event, lambda_context):
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'METADATA', 'EventName': 'A'})
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt2', 'SK': 'METADATA', 'EventName': 'B'})
    # Should not return this registration
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'REG#u@e.com', 'UserEmail': 'u@e.com'})
    
    response = lambda_handler(api_gateway_event(), lambda_context)
    assert response['statusCode'] == 200
    
    events = json.loads(response['body'])['events']
    assert len(events) == 2
    assert all(e['SK'] == 'METADATA' for e in events)
