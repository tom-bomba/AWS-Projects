# Stage 3
for hosting container-based infra plans

Requires the non-admin account credentials for MySQL DB to be defined in Secrets Manager.
Single Secret for both values, 'username' and 'password'.

Admin SQL account creds are AWS Managed.

Steps to run:
1. Create db creds secret and note location
2. Build webserver, push to ECR.
3. Pull CWA agent [amazon/cloudwatch-agent:latest](https://hub.docker.com/r/amazon/cloudwatch-agent) and push to ECR so it's available from private endpoint (or add a NAT GW and pull directly from Amazon)
4. Fill in terraform.tfvars
5. Apply resources in /infra/
6. Dump outputs from infra deployment to /k8s/outputs.json
7. Apply resources in /k8s/
