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
    logger.info(event)
    client = boto3.client('cognito-idp')
    
    # Handle logout request
    body_dict = json.loads(event['body'])  
    access_token = body_dict['access_token']
    try:
        client.global_sign_out(
            AccessToken=access_token
        )
        logger.info("User logged out successfully")
        return {
            'statusCode': 200,
            "headers": {"Access-Control-Allow-Origin": "*"},
            'body': json.dumps({
                'message': 'User logged out successfully'
            })
        }
    except client.exceptions.NotAuthorizedException:
        logger.error("User not authorized")
        return {
            'statusCode': 400,
            "headers": {"Access-Control-Allow-Origin": "*"},
            'body': json.dumps('User not authorized')
        }
    except Exception as e:
        logger.exception(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            "headers": {"Access-Control-Allow-Origin": "*"},
            'body': json.dumps(f'Error: {str(e)}')
        }
