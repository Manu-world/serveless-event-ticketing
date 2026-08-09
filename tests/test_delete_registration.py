import json
from delete_registration import lambda_handler

def test_delete_missing_id(api_gateway_event, lambda_context):
    response = lambda_handler(api_gateway_event(), lambda_context)
    assert response['statusCode'] == 400

def test_delete_not_found(mock_dynamodb, api_gateway_event, lambda_context):
    event = api_gateway_event(path_parameters={'id': '123e4567-e89b-12d3-a456-426614174000'})
    response = lambda_handler(event, lambda_context)
    assert response['statusCode'] == 404

def test_delete_success(mock_dynamodb, api_gateway_event, lambda_context):
    reg_id = '123e4567-e89b-12d3-a456-426614174000'
    mock_dynamodb.put_item(Item={'PK': 'EVENT#evt1', 'SK': 'REG#u@e.com', 'RegistrationId': reg_id})
    
    event = api_gateway_event(path_parameters={'id': reg_id})
    response = lambda_handler(event, lambda_context)
    
    assert response['statusCode'] == 200
    assert 'cancelled successfully' in json.loads(response['body'])['message']
    
    # Verify deleted
    items = mock_dynamodb.scan()['Items']
    assert len(items) == 0
