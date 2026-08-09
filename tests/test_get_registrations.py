import json
from get_registrations import lambda_handler

def test_get_registrations_missing_email(api_gateway_event, lambda_context):
    response = lambda_handler(api_gateway_event(), lambda_context)
    assert response['statusCode'] == 400

def test_get_registrations_success(mock_dynamodb, api_gateway_event, lambda_context):
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'REG#test@example.com', 'UserEmail': 'test@example.com'})
    
    event = api_gateway_event(path_parameters={'email': 'test@example.com'})
    response = lambda_handler(event, lambda_context)
    
    assert response['statusCode'] == 200
    regs = json.loads(response['body'])['registrations']
    assert len(regs) == 1
    assert regs[0]['UserEmail'] == 'test@example.com'
