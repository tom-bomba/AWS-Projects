## EC2 TO SERVERLESS

Feel free to take a look and take a template or two!

Some of these templates go beyond free tier. Since these are just play environments, no_log isn't enabled. User beware.

### Stage 1:
Resources created:
- VPC (1)
- Subnet (1)
- InternetGateway (1)
- VPCGatewayAttachment (1)
- RouteTable (1)
- Route (1)
- SubnetRouteTableAssociation (1)
- SecurityGroup (1)
- Role (1)
- InstanceProfile (1)
- Instance (1)

Requires:
- CloudWatch Agent config in Parameter Store as "AmazonCloudWatch-linux"
- awscli credentials to complete the required creates/modifications
- pre-generated ssh key for the Ansible connection. I use a static testing key for simplicity.
- s3 bucket at template-specified location containing your webserver files.

### Stage 2:
Changes: 
1. Switch from CloudFormation to Terraform to deploy resources and Ansible to config the instance.
2. Change coming soon page to a page to demonstrate user input then recalling that input. Users can register @register.php then submit fortunes @submit_fortunes.php. Finally, they can retrieve a random fortune, along with the submitting user's username @random_fortune.php.

To Run:
1. terraform init
2. terraform apply
3. ansible-playbook -i inventory.yaml webserver_playbook.yaml -v

Resources created:
- VPC (1)
- Subnet (1)
- InternetGateway (1)
- VPCGatewayAttachment (1)
- RouteTable (1)
- Route (1)
- SubnetRouteTableAssociation (1)
- SecurityGroup (1)
- Role (1)
- InstanceProfile (1)
- Instance (1)

Requires:
- 2 Passwords in Secrets Manager:
  - ${aws_secret_location}/db_root_pass
  - ${aws_secret_location}/db_user_pass
- CloudWatch Agent config in Parameter Store as "AmazonCloudWatch-linux"
- awscli credentials to complete the required creates/modifications
- pre-generated ssh key for the Ansible connection. I use a static testing key for simplicity.
- s3 bucket at template-specified location containing your webserver files.

### Stage 3:
Changes: 
1. Switch DB from local mariadb to Aurora Serverless v2 with 2 reader instances for 1 instance per AZ.
2. Create launch template from instance, stick behind LB and ASG.

To Run:
1. Create a basic ec2 instance. See stage2's ec2-instance for which options I used. Add the IP to inventory.yaml
2. ansible-playbook -i inventory.yaml webserver_playbook.yaml -v
3. Supply AMI to terraform's launch template
4. terraform init
5. terraform apply

Resources created:

- aws_iam_role (2)
- aws_iam_instance_profile (1)
- aws_vpc (1)
- aws_internet_gateway (1)
- aws_subnet (3)
- aws_route_table (1)
- aws_route_table_association (3)
- aws_security_group (2)
- aws_vpc_security_group_egress_rule (2)
- aws_vpc_security_group_ingress_rule (4)
- aws_db_subnet_group (1)
- aws_rds_cluster (1)
- aws_rds_cluster_instance (3)
- aws_lambda_function (1)
- aws_lambda_invocation (1)
- aws_lb (1)
- aws_lb_listener (1)
- aws_launch_template (1)
- aws_lb_target_group (1)
- aws_autoscaling_group (1)

Requires:
- 2 Passwords in Secrets Manager:
  - ${aws_secret_location}/db_root_pass
  - ${aws_secret_location}/db_user_pass
- CloudWatch Agent config in Parameter Store as "AmazonCloudWatch-linux"
- awscli credentials to complete the required creates/modifications
- s3 bucket at template-specified location containing your webserver files.
- Appropriate lambda code and packages zipped in terraform folder(requires pymysql)

### Stage 4:
Changes: 
1. Switch auth to Cognito from local db.
2. Drop EC2 altogether and replace with S3 + API GW + Lambda.


- aws_iam_role (2)
- aws_iam_policy (1)
- aws_iam_role_policy_attachment (1)
- aws_s3_bucket_policy (1)
- aws_s3_bucket (1)
- aws_s3_bucket_public_access_block (1)
- aws_s3_bucket_website_configuration (1)
- aws_s3_bucket_versioning (1)
- aws_vpc (1)
- aws_internet_gateway (1)
- aws_subnet (3)
- aws_route_table (1)
- aws_route_table_association (3)
- aws_security_group (1)
- aws_vpc_security_group_egress_rule (1)
- aws_vpc_security_group_ingress_rule (1)
- aws_db_subnet_group (1)
- aws_rds_cluster (1)
- aws_rds_cluster_instance (3)
- aws_lambda_layer_version (1)
- aws_lambda_function (6)
- aws_lambda_invocation (1)
- aws_api_gateway_rest_api (1)
- aws_api_gateway_authorizer (1)
- aws_api_gateway_resource (5)
- aws_lambda_permission (5)
- aws_api_gateway_method (12)
- aws_api_gateway_integration (10)
- aws_api_gateway_method_response (10)
- aws_api_gateway_integration_response (4)
- aws_api_gateway_stage (1)
- aws_api_gateway_deployment (1)
- null_resource (1)

Requires:
- 2 Passwords in Secrets Manager:
  - ${aws_secret_location}/db_root_pass
  - ${aws_secret_location}/db_user_pass
- 1 client_secret in Secrets Manager:
  - dev/cognito/fortunes/client_secret
- CloudWatch Agent config in Parameter Store as "AmazonCloudWatch-linux"
- awscli credentials to complete the required creates/modifications
- This template uses files within other dirs, expecting a relative path. Maintain a simliar dir structure.
- Appropriate lambda code and packages zipped in lambda folder folder (requires pymysql)
- pymysql as layer.zip in lambda dir.
- Existing Cognito user pool
- if you want to change things around, a sed replace on "fortunes" and "client_id" and "user_pool" should do the trick. repackage the lambdas after the replace.


