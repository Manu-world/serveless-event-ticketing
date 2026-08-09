from services.auth.authorizer import lambda_handler

def test_authorizer_missing_key(api_gateway_event, lambda_context):
    response = lambda_handler(api_gateway_event(), lambda_context)
    assert response['isAuthorized'] is False

def test_authorizer_invalid_key(mock_ssm, api_gateway_event, lambda_context):
    event = api_gateway_event(headers={'x-api-key': 'wrong'})
    response = lambda_handler(event, lambda_context)
    assert response['isAuthorized'] is False

def test_authorizer_valid_key(mock_ssm, api_gateway_event, lambda_context):
    event = api_gateway_event(headers={'x-api-key': 'secret-api-key-123'})
    response = lambda_handler(event, lambda_context)
    assert response['isAuthorized'] is True
