
locals {
  required_tags = {
      project     = var.project_name
      environment = var.environment
  }
  tags = merge(var.resource_tags, local.required_tags)
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.db_secrets.secret_string
  )
  cog_creds = jsondecode(
    data.aws_secretsmanager_secret_version.cognito_secrets.secret_string
  )
}

locals {
  name_suffix = "${var.project_name}-${var.environment}"
}

# Lambda role
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role2"
  assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
          {
            Action  = "sts:AssumeRole"
            Effect  = "Allow"
            Sid     = ""
            Principal = {
                Service = "lambda.amazonaws.com"
            }
          },

      ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSLambdaExecute", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]


}
resource "aws_iam_policy" "cognito_policy" {
  name        = "CognitoAccessPolicy"
  description = "Policy for allowing access to Cognito"
  policy      = data.aws_iam_policy_document.cognito_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_cognito_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cognito_policy.arn
}
# API role
resource "aws_iam_role" "api_role" {
  name = "api_role"
  assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
          {
            Action  = "sts:AssumeRole"
            Effect  = "Allow"
            Sid     = ""
            Principal = {
                Service = "apigateway.amazonaws.com"
            }
          },

      ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSLambdaExecute", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]


}

# make the s3 bucket which will act as our frontend
resource "random_pet" "name" {
  length = 4
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket_webserver_v4.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_s3_bucket" "bucket_webserver_v4" {
  bucket_prefix = "webserver-v4-"
 
}

resource "aws_s3_bucket_public_access_block" "bucket_block_pub_access" {
  bucket = aws_s3_bucket.bucket_webserver_v4.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  depends_on = [null_resource.fix_js]
  provisioner "local-exec" {
  command = "aws s3 sync ../webserver s3://${aws_s3_bucket.bucket_webserver_v4.id}"
  
  }
}

resource "aws_s3_bucket_website_configuration" "bucket_website_config" {
  bucket = aws_s3_bucket.bucket_webserver_v4.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}
resource "aws_s3_bucket_versioning" "bucket_versioning_config" {
  bucket = aws_s3_bucket.bucket_webserver_v4.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Make the network resources: 1 vpc, 3 subnets in 3 AZs.
resource "aws_vpc" "app_vpc" {
  cidr_block              = "10.0.0.0/16"
  enable_dns_hostnames    = true
  enable_dns_support      = true
  tags = {
      Name = "app_vpc_${local.name_suffix}"
  }
}

resource "aws_internet_gateway" "app_vpc_ig" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
      Name = "app_vpc_ig_${local.name_suffix}"
  }
}

resource "aws_subnet" "app_subnet_1" {
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = "10.0.1.0/24"
  tags = {
      Name = "app_vpc_subnet_${local.name_suffix}"
  }
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = "10.0.2.0/24"
  tags = {
      Name = "app_vpc_subnet_2_${local.name_suffix}"
  }
}

resource "aws_subnet" "app_subnet_3" {
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = data.aws_availability_zones.available.names[2]
  cidr_block = "10.0.3.0/24"
  tags = {
      Name = "app_vpc_subnet_3_${local.name_suffix}"
  }
}

# Route Table

resource "aws_route_table" "app_route_table_1" {
  vpc_id = aws_vpc.app_vpc.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.app_vpc_ig.id
  }
  tags = {
      Name = "app_vpc_route_table_${local.name_suffix}"
  }
}


resource "aws_route_table_association" "app_route_table_association_1" {
  subnet_id      = aws_subnet.app_subnet_1.id
  route_table_id = aws_route_table.app_route_table_1.id
}

resource "aws_route_table_association" "app_route_table_association_2" {
  subnet_id      = aws_subnet.app_subnet_2.id
  route_table_id = aws_route_table.app_route_table_1.id
}

resource "aws_route_table_association" "app_route_table_association_3" {
  subnet_id      = aws_subnet.app_subnet_3.id
  route_table_id = aws_route_table.app_route_table_1.id
}

# Security Groups
resource "aws_security_group" "app_sg_1" {
    name        = "app_sg_1"
    description = "security group applied to the app webserver"
    vpc_id      = aws_vpc.app_vpc.id
    tags = {
        Name = "app_security_group_${local.name_suffix}"
    }
}
resource "aws_vpc_security_group_egress_rule" "app_sg_1_egressrule_1" {
  security_group_id = aws_security_group.app_sg_1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

resource "aws_vpc_security_group_ingress_rule" "app_sg_1_ingressrule_2" {
  security_group_id = aws_security_group.app_sg_1.id
  referenced_security_group_id = aws_security_group.app_sg_1.id
  ip_protocol       = -1
}

# create Aurora
resource "aws_db_subnet_group" "app_db_subnet_group_1" {
  name       = "app_db_subnet_group_1"
  subnet_ids = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
  tags = {
    Name = "app_db_subnet_group"
  }
}


resource "aws_rds_cluster" "app_db_cluster_1" {
  cluster_identifier        = "app-db-cluster-1"
  availability_zones        = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  database_name             = var.db_name
  engine                    = "aurora-mysql"
  engine_mode               = "provisioned"
  engine_version            = "8.0.mysql_aurora.3.03.1"
  vpc_security_group_ids    = [aws_security_group.app_sg_1.id]
  skip_final_snapshot       = true
  db_subnet_group_name      = aws_db_subnet_group.app_db_subnet_group_1.name
  master_username           = local.db_creds.db_root_user
  master_password           = local.db_creds.db_root_pass
  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}
resource "aws_rds_cluster_instance" "app_cluster_instances" {
  count              = 3
  identifier         = "app-aurora-cluster-${count.index}"
  cluster_identifier = aws_rds_cluster.app_db_cluster_1.id
  instance_class     = "db.serverless"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.03.1"

}


