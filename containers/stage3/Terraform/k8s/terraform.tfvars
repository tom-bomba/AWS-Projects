my_cidr = "X.X.X.X/32"
db_name = "fortunes"
image   = "account.endpoint/repo:tag"
cw_image = "account.endpoint/repo:tag"
# This should be where your non-admin user credentials for the MySQL RDS DB. i.e. "dev/db_creds/webserver_k8s"
# Master user credentials are managed. 
aws_secrets_loc = "path/to/secrets"
