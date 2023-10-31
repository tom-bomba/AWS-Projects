import json
import logging
import pymysql
import os
import random

host = os.getenv('DB_HOST')
user = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')
db_name = os.getenv('DB_NAME')
rds_endpoint = os.getenv('RDS_ENDPOINT')

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def random_fortune():
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
            logger.info("Retrieving random fortune...")
            sql = "SELECT * FROM fortunes ORDER BY RAND() LIMIT 1"
            cursor.execute(sql)

            fortune = cursor.fetchone()

            if fortune is None:
                logger.error("No Fortunes available. Try submitting one yourself")
                return None
            
            logger.info(f"Selected Fortune: {fortune}")

            return fortune
        
    finally:
        connection.close()

def lambda_handler(event, context):
    try:
        fortune =  random_fortune()
        if fortune is None:
            return {
                'statusCode': 404,
                'headers': {"Access-Control-Allow-Origin":"*"},
                'body': json.dumps('No fortunes found!')
            }
        return {
            'statusCode': 200,
            "headers": {"Access-Control-Allow-Origin":"*"},
            'body': json.dumps(f"{fortune['user_id']} says {fortune['fortune']}")
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Server Error: {str(e)}')
        }