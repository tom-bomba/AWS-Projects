RDS Aurora & EKS managed nodes.

## Requirements

1. Private ECR repo with 2 images:
   1. the webserver being run. Build, tag & push the Docker img.
   2. CloudWatch Agent image for logging sidecar. This can be duplicated to the private repo or you can add a NAT gateway to allow it to pull from the source.
  
2. Secrets Manager holding DB creds. Swap out the pull in main.tf under locals and data.tf if you don't want to use AWS SM.

3. Replace vars in BOTH terrraform.tfvars (infra & k8s).
