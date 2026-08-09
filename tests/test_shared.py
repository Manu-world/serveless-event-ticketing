import pytest
from decimal import Decimal
import json
from shared import validate_email, validate_uuid, DecimalEncoder, build_response

def test_validate_email():
    assert validate_email("test@example.com") is True
    assert validate_email("invalid-email") is False
    assert validate_email("@example.com") is False

def test_validate_uuid():
    assert validate_uuid("123e4567-e89b-12d3-a456-426614174000") is True
    assert validate_uuid("invalid-uuid") is False

def test_decimal_encoder():
    data = {'val1': Decimal('10.5'), 'val2': Decimal('10')}
    encoded = json.dumps(data, cls=DecimalEncoder)
    assert '10.5' in encoded
    # 10.0 becomes 10 (int)
    assert '10' in encoded

def test_build_response():
    resp = build_response(200, {'msg': 'ok'})
    assert resp['statusCode'] == 200
    assert 'Access-Control-Allow-Origin' in resp['headers']
    assert json.loads(resp['body'])['msg'] == 'ok'
