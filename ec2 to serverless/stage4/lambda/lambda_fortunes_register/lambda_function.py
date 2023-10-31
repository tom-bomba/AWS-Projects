import json
import os
import boto3
import hashlib
import hmac
import base64
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def create_secret_hash(username, client_id):
    msg = username + client_id
    dig = hmac.new(str(os.environ['client_secret']).encode('utf-8'), 
                   msg=str(msg).encode('utf-8'), 
                   digestmod=hashlib.sha256).digest()
    d2 = base64.b64encode(dig).decode()
    return d2

def lambda_handler(event, context):
    # Initialize Cognito client
    client = boto3.client('cognito-idp')

    if event['httpMethod'] == 'POST':
        # Parse the body
        body = json.loads(event['body'])
        username = body['username']
        password = body['password']

        if event['resource'] == '/register':
            try:
                # Handle register request
                logger.info(f"Registering user: {username}")
                response = client.admin_create_user(
                    UserPoolId='user_pool_id',
                    Username=username,
                    TemporaryPassword=password,
                    MessageAction='SUPPRESS'  # This suppresses the welcome message.
                )


                # set a permanent password and confirm the user account.
                client.admin_set_user_password(
                    UserPoolId='user_pool_id',
                    Username=username,
                    Password=password,
                    Permanent=True
                )

                logger.info(f"User registered successfully: {username}")
                return {
                    'statusCode': 200,
                    'body': json.dumps('User registered successfully')
                }
            except client.exceptions.UsernameExistsException:
                logger.error(f"User already exists: {username}")
                return {
                    'statusCode': 400,
                    'body': json.dumps('User already exists')
                }
            except Exception as e:
                logger.exception(f"Error: {str(e)}")
                return {
                    'statusCode': 500,
                    'body': json.dumps(str(e))
                }

    logger.error("Invalid request")
    return {
        'statusCode': 400,
        'body': json.dumps('Invalid request')
    }
