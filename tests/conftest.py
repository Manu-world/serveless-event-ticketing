import os
import boto3
import pytest
from moto import mock_aws
import sys

# Ensure src is in path so handlers can import shared
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

@pytest.fixture(scope='function')
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'
    os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'

@pytest.fixture(scope='function')
def mock_env():
    os.environ['TABLE_NAME'] = 'test-table'
    os.environ['SNS_TOPIC_ARN'] = 'arn:aws:sns:us-east-1:123456789012:test-topic'
    os.environ['EMAIL_PROVIDER'] = 'none'
    os.environ['ADMIN_API_KEY_SSM_PARAM'] = '/test/admin-api-key'

@pytest.fixture(scope='function')
def mock_dynamodb(aws_credentials, mock_env):
    with mock_aws():
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        
        table = dynamodb.create_table(
            TableName='test-table',
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'},
                {'AttributeName': 'UserEmail', 'AttributeType': 'S'},
                {'AttributeName': 'RegistrationId', 'AttributeType': 'S'}
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'UserEmailIndex',
                    'KeySchema': [
                        {'AttributeName': 'UserEmail', 'KeyType': 'HASH'},
                        {'AttributeName': 'PK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'SKIndex',
                    'KeySchema': [
                        {'AttributeName': 'SK', 'KeyType': 'HASH'},
                        {'AttributeName': 'PK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'RegistrationIdIndex',
                    'KeySchema': [
                        {'AttributeName': 'RegistrationId', 'KeyType': 'HASH'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        yield table

@pytest.fixture(scope='function')
def mock_sns(aws_credentials):
    with mock_aws():
        sns = boto3.client('sns', region_name='us-east-1')
        topic = sns.create_topic(Name='test-topic')
        yield topic['TopicArn']

@pytest.fixture(scope='function')
def mock_ssm(aws_credentials):
    with mock_aws():
        ssm = boto3.client('ssm', region_name='us-east-1')
        ssm.put_parameter(
            Name='/test/admin-api-key',
            Value='secret-api-key-123',
            Type='SecureString'
        )
        yield ssm

@pytest.fixture
def lambda_context():
    class LambdaContext:
        def __init__(self):
            self.function_name = "test-func"
            self.memory_limit_in_mb = 128
            self.invoked_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:test-func"
            self.aws_request_id = "test-request-id"
    return LambdaContext()

@pytest.fixture
def api_gateway_event():
    def _event(body=None, path_parameters=None, headers=None):
        return {
            'body': body,
            'pathParameters': path_parameters or {},
            'headers': headers or {}
        }
    return _event
