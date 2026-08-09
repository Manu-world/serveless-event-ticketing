import json
from services.registrations.handlers.create import lambda_handler

def test_register_missing_fields(api_gateway_event, lambda_context):
    event = api_gateway_event(body=json.dumps({}))
    response = lambda_handler(event, lambda_context)
    assert response['statusCode'] == 400
    assert 'error' in json.loads(response['body'])

def test_register_invalid_email(api_gateway_event, lambda_context):
    event = api_gateway_event(body=json.dumps({'eventId': 'evt1', 'email': 'bad'}))
    response = lambda_handler(event, lambda_context)
    assert response['statusCode'] == 400

def test_register_event_not_found(mock_dynamodb, mock_sns, api_gateway_event, lambda_context):
    event = api_gateway_event(body=json.dumps({'eventId': 'evt1', 'email': 'test@example.com'}))
    response = lambda_handler(event, lambda_context)
    assert response['statusCode'] == 404

def test_register_success(mock_dynamodb, mock_sns, api_gateway_event, lambda_context):
    # Seed event
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'METADATA', 'EventId': 'evt1'})
    
    event = api_gateway_event(body=json.dumps({'eventId': 'evt1', 'email': 'test@example.com'}))
    response = lambda_handler(event, lambda_context)
    
    assert response['statusCode'] == 201
    body = json.loads(response['body'])
    assert 'registrationId' in body
    assert body['message'] == 'Successfully registered'
    
    # Verify DB
    items = mock_dynamodb.scan()['Items']
    regs = [i for i in items if i['SK'].startswith('REG#')]
    assert len(regs) == 1
    assert regs[0]['UserEmail'] == 'test@example.com'

def test_register_duplicate(mock_dynamodb, mock_sns, api_gateway_event, lambda_context):
    # Seed event and registration
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'METADATA', 'EventId': 'evt1'})
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'REG#test@example.com', 'RegistrationId': '123'})
    
    event = api_gateway_event(body=json.dumps({'eventId': 'evt1', 'email': 'test@example.com'}))
    response = lambda_handler(event, lambda_context)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['message'] == 'Already registered'
    assert body['registrationId'] == '123'
