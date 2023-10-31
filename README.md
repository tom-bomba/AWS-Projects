# Projects

Feel free to take a look and take a template or two!

Some of these templates go beyond free tier. These are intended for testing, not production.

I apologize for the state of the webservers. Because the focus isn't on webdev, they are simplistic and insecure for prod use. Feel free to drop in your own!

## EC2 TO SERVERLESS
Create a simple webserver on an EC2 instance. It should be able to store/retrieve user-provided info as well as authenticate users. Make it highly available and decouple DB from the frontend. Finally, refactor to allow full serverless implementation: static on s3, backend handled by lambda + API GW.
#### Stage 1:
Simple webserver that displays a single "Coming Soon..." page. Single instance in single AZ.
#### Stage 2:
Webserver allows for user input and deploy with Terraform + Ansible to decouple infrastructure and config.
#### Stage 3:
Create std. image for the webserver. Deploy it using LB + ASG spread across 3 subnets in 3 AZs. Switch DB to Aurora Serverless v2 (3 instances across 3 AZs) to decouple the frontend and the db.
#### Stage 4:
Switch from ec2 to S3 Static Website Hosting + API GW + Lambda. DB remains the same. User auth is now handled by Cognito instead of local Users table.

## Containers
#### Stage 1:
Replicated Stage 3 of EC2 to Serverless, but running the webserver as an ECS service. DB BE is still Aurora Severless v2 for simple mgmt.

#### Stage 2:
Switch from ECS to EKS.

#### Stage 3:
Add Redis for sessions, move db creds to Kubernetes secrets + AWS SecretsManager. Templated more variables.

## CI/CD
Coming soon...
