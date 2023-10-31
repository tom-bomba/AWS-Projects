import json
import logging
import pymysql
import os

host = os.getenv('DB_HOST')
user = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')
db_name = os.getenv('DB_NAME')
rds_endpoint = os.getenv('RDS_ENDPOINT')

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def put_fortune(user_id, fortune):
    logger.info("Creating connection...")
    try:
        connection = pymysql.connect(host=rds_endpoint,
                                     user=user,
                                     password=password,
                                     db=db_name,
                                     cursorclass=pymysql.cursors.DictCursor)
    except pymysql.MySQLError as e:
        logger.error("ERROR: Unexpected error: Could not connect to MySQL instance.")
        logger.error(e)
        return

    try:
        with connection.cursor() as cursor:
            logger.info("Inserting fortune...")
            sql = "INSERT INTO fortunes (user_id, fortune) VALUES (%s, %s)"
            cursor.execute(sql, (user_id, fortune))

        connection.commit()
    finally:
        connection.close()

    return('Fortune submitted correctly!')
def lambda_handler(event, context):
    # Extract fortune from the event
    logger.info(json.dumps(event))
    logger.info(event.keys())
    body = json.loads(event['body'])
    fortune = body['fortune']
    
    # Extract the username from the JWT payload (requestContext.authorizer.claims)
    user_id = body['username']

    # Establish connection to the Aurora Serverless MySQL database
    try:
        put_fortune(user_id, fortune)
        return {
            'statusCode': 200,
            "headers": {"Access-Control-Allow-Origin":"*"},
            'body': json.dumps('Submission Success!')
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Server Error: {str(e)}')
        }
