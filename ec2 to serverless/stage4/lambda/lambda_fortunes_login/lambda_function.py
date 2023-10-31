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
    client = boto3.client('cognito-idp')

    if event['httpMethod'] == 'POST':
        body = json.loads(event['body'])
        username = body.get('username')
        password = body.get('password')
        client_id = "client_id"

        if event['resource'] == '/login':
            try:
                secret_hash = create_secret_hash(username, client_id)
                response = client.initiate_auth(
                    AuthFlow='USER_PASSWORD_AUTH',
                    AuthParameters={
                        'USERNAME': username,
                        'PASSWORD': password,
                        'SECRET_HASH': secret_hash
                    },
                    ClientId=client_id
                )

                if response.get('AuthenticationResult'):
                    logger.info(f"User logged in successfully: {username}")
                    id_token = response['AuthenticationResult']['IdToken']
                    access_token = response['AuthenticationResult']['AccessToken']
                    return {
                        'statusCode': 200,
                        "headers": {"Access-Control-Allow-Origin":"*"},
                        'body': json.dumps({
                            'message': 'User logged in successfully',
                            'id_token': id_token,
                            'access_token': access_token
                        })
                    }

                else:
                    logger.error(f"Login failed for user: {username}")
                    return {
                        'statusCode': 400,
                        "headers": {"Access-Control-Allow-Origin":"*"},
                        'body': json.dumps('Login failed')
                    }
            except client.exceptions.UserNotFoundException:
                logger.error(f"User not found: {username}")
                return {
                    'statusCode': 400,
                    "headers": {"Access-Control-Allow-Origin":"*"},
                    'body': json.dumps('User not found')
                }
            except client.exceptions.NotAuthorizedException:
                logger.error(f"Incorrect username or password: {username}")
                return {
                    'statusCode': 400,
                    "headers": {"Access-Control-Allow-Origin":"*"},
                    'body': json.dumps('Incorrect username or password')
                }
            except Exception as e:
                logger.exception(f"Error: {str(e)}")
                return {
                    'statusCode': 500,
                    "headers": {"Access-Control-Allow-Origin":"*"},
                    'body': json.dumps(f'Error: {str(e)}')
                }

    elif event['httpMethod'] == 'GET':
        if event['resource'] == '/random_fortune':
            # Handle random fortune retrieval here
            pass
        elif event['resource'] == '/submit_fortune':
            # Handle fortune submission here
            pass

    logger.error("Invalid request")
    return {
        'statusCode': 400,
        "headers": {"Access-Control-Allow-Origin":"*"},
        'body': json.dumps('Invalid request')
    }
