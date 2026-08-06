import json
from src.get_events import build_response

def test_build_response():
    body = {"events": []}
    response = build_response(200, body)
    
    assert response['statusCode'] == 200
    assert response['headers']['Access-Control-Allow-Origin'] == '*'
    assert json.loads(response['body']) == body