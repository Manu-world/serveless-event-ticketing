import os
import boto3

ssm = boto3.client('ssm')

def lambda_handler(event, context):
    try:
        # HTTP API v2 Authorizer payload
        # headers are lowercased
        api_key = event.get('headers', {}).get('x-api-key')
        
        if not api_key:
            print("Missing x-api-key header")
            return {"isAuthorized": False}
            
        # Get admin API key from SSM
        # The key name is passed via env var
        ssm_param_name = os.environ.get('ADMIN_API_KEY_SSM_PARAM')
        
        response = ssm.get_parameter(
            Name=ssm_param_name,
            WithDecryption=True
        )
        expected_api_key = response['Parameter']['Value']
        
        if api_key == expected_api_key:
            print("Authorization successful")
            return {"isAuthorized": True}
        else:
            print("Invalid API key provided")
            return {"isAuthorized": False}
            
    except Exception as e:
        print(f"Authorizer error: {str(e)}")
        return {"isAuthorized": False}
