# Tags
# Stuff DB Creds from Secrets Manager
locals {
  required_tags = {
      project     = var.project_name
      environment = var.environment
  }
  tags = merge(var.resource_tags, local.required_tags)
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.db_secrets.secret_string
  )
}

locals {
  name_suffix = "${var.project_name}-${var.environment}"
}

# IAM Roles
#
# Lamba Role
resource "aws_iam_policy" "lambda_secrets" {
  name        = "lambda_secrets"
  description = "Permission to read secrets for lambda to setup db creds."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
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
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSLambdaExecute", 
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  policy_arn = aws_iam_policy.lambda_secrets.arn
  role       = aws_iam_role.lambda_role.name
}

# EKS Node Role
resource "aws_iam_policy" "cloudwatch_logs_access" {
  name        = "cloudwatch_logs_access"
  description = "Policy for CloudWatch Logs read/write access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Effect   = "Allow"
        Resource = "*" 
      }
    ]
  })
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks_node_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com",
          "eks.amazonaws.com"]
        }
      },
    ]
  })

  managed_policy_arns = [
   "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
} 

# EKS Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com",
          "eks.amazonaws.com"]
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]
} 

# Attach CloudWatch Logs Access Policy to EKS Node Role
resource "aws_iam_role_policy_attachment" "eks_node_role_cloudwatch_logs_access_attach" {
  policy_arn = aws_iam_policy.cloudwatch_logs_access.arn
  role       = aws_iam_role.eks_node_role.name
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

resource "aws_subnet" "lb_subnet_1" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "lb_subnet_1_${local.name_suffix}"
  }
} 

resource "aws_subnet" "lb_subnet_2" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "lb_subnet_2_${local.name_suffix}"
  }
} 

resource "aws_subnet" "lb_subnet_3" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.6.0/24"
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "lb_subnet_3_${local.name_suffix}"
  }
}

# Route Tables
resource "aws_route_table" "app_private_route_table" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "app_private_route_table_${local.name_suffix}"
  }
}

resource "aws_route_table" "lb_public_route_table" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_vpc_ig.id
  }
  tags = {
    Name = "lb_public_route_table_${local.name_suffix}"
  }
}

# Associate private route table with Application subnets
resource "aws_route_table_association" "app_private_route_table_1" {
  subnet_id      = aws_subnet.app_subnet_1.id
  route_table_id = aws_route_table.app_private_route_table.id
}

resource "aws_route_table_association" "app_private_route_table_2" {
  subnet_id      = aws_subnet.app_subnet_2.id
  route_table_id = aws_route_table.app_private_route_table.id
}

resource "aws_route_table_association" "app_private_route_table_3" {
  subnet_id      = aws_subnet.app_subnet_3.id
  route_table_id = aws_route_table.app_private_route_table.id
}



# Associate public route table with Load Balancer subnets
resource "aws_route_table_association" "lb_public_route_table_assoc_1" {
  subnet_id      = aws_subnet.lb_subnet_1.id
  route_table_id = aws_route_table.lb_public_route_table.id
}

resource "aws_route_table_association" "lb_public_route_table_assoc_2" {
  subnet_id      = aws_subnet.lb_subnet_2.id
  route_table_id = aws_route_table.lb_public_route_table.id
}

resource "aws_route_table_association" "lb_public_route_table_assoc_3" {
  subnet_id      = aws_subnet.lb_subnet_3.id
  route_table_id = aws_route_table.lb_public_route_table.id
}


# Security Groups
#
# Load Balancer SG
resource "aws_security_group" "lb_sg_1" {
    name        = "lb_sg_1"
    description = "security group applied to the load balancer"
    vpc_id      = aws_vpc.app_vpc.id
    tags = {
        Name = "lb_security_group_${local.name_suffix}"
    }
}

resource "aws_vpc_security_group_egress_rule" "lb_sg_1_egressrule_1" {
  security_group_id = aws_security_group.lb_sg_1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

resource "aws_vpc_security_group_ingress_rule" "lb_sg_1_ingressrule_1" {
  security_group_id = aws_security_group.lb_sg_1.id
  cidr_ipv4         = var.my_cidr
  ip_protocol       = -1
}
resource "aws_vpc_security_group_ingress_rule" "lb_sg_1_ingressrule_2" {
  security_group_id = aws_security_group.lb_sg_1.id
  referenced_security_group_id = aws_security_group.lb_sg_1.id
  ip_protocol       = -1
}
resource "aws_vpc_security_group_ingress_rule" "lb_sg_1_ingressrule_3" {
  security_group_id = aws_security_group.lb_sg_1.id
  referenced_security_group_id = aws_security_group.app_sg_1.id
  ip_protocol       = -1
}

# Application SG
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

resource "aws_vpc_security_group_ingress_rule" "app_sg_1_ingressrule_1" {
  security_group_id = aws_security_group.app_sg_1.id
  referenced_security_group_id = aws_security_group.lb_sg_1.id
  ip_protocol       = -1
}

resource "aws_vpc_security_group_ingress_rule" "app_sg_1_ingressrule_2" {
  security_group_id = aws_security_group.app_sg_1.id
  referenced_security_group_id = aws_security_group.app_sg_1.id
  ip_protocol       = -1
}

resource "aws_vpc_security_group_ingress_rule" "app_sg_1_ingressrule_cluster" {
  security_group_id = aws_security_group.app_sg_1.id
  referenced_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id

  ip_protocol       = -1
}

# create Aurora
resource "aws_db_subnet_group" "app_db_subnet_group_1" {
  name       = "app_db_subnet_group_1"
  subnet_ids = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
  tags = {
    Name = "app_db_subnet_group_${local.name_suffix}"
  }
}

# Serverless v2
resource "aws_rds_cluster" "app_db_cluster_1" {
  cluster_identifier                  = "app-db-cluster-1"
  availability_zones                  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  database_name                       = var.db_name
  engine                              = "aurora-mysql"
  engine_mode                         = "provisioned"
  engine_version                      = "8.0.mysql_aurora.3.03.1"
  vpc_security_group_ids              = [aws_security_group.app_sg_1.id]
  skip_final_snapshot                 = true
  db_subnet_group_name                = aws_db_subnet_group.app_db_subnet_group_1.name
  master_username                     = "admin"
  manage_master_user_password         = true

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

# Lambda provision our two tables
resource "aws_lambda_function" "lambda_config_db" {
  filename      = "lambda_function.zip"
  function_name = "aurora_config_tables"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "lambda_function.lambda_handler"
  timeout       = 15
  vpc_config {
    security_group_ids = [aws_security_group.app_sg_1.id]
    subnet_ids = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
  }
}

resource "aws_lambda_invocation" "lambda_execute" {
  function_name = aws_lambda_function.lambda_config_db.function_name
  input = jsonencode({
    rds_endpoint = aws_rds_cluster.app_db_cluster_1.endpoint
    region = data.aws_region.current.name
    db_root_secret = data.aws_secretsmanager_secret.master_secret.name
    db_user_secret = var.aws_secrets_loc
    user_table_name = var.users_table_name
    app_table_name = var.app_table_name
    db_name = var.db_name
  })
  depends_on = [aws_lambda_function.lambda_config_db, aws_rds_cluster_instance.app_cluster_instances, aws_rds_cluster.app_db_cluster_1, aws_iam_role_policy_attachment.lambda_role_attach]
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "app_cache_subnet_group" {
  name       = "app-cache-subnet-group2"
  subnet_ids = [
    aws_subnet.app_subnet_1.id,
    aws_subnet.app_subnet_2.id,
    aws_subnet.app_subnet_3.id
  ]
}

resource "aws_elasticache_replication_group" "app_cache_rep_group" {
  replication_group_id          = "app-cache-rep-group2"
  description                   = "App Cache Replication Group"
  engine                        = "redis"
  engine_version                = "7.0"
  node_type                     = "cache.t3.micro"
  automatic_failover_enabled    = true  # Enable automatic failover
  multi_az_enabled              = true  # Enable multi-AZ
  parameter_group_name          = "default.redis7"
  port                          = 6379
  subnet_group_name             = aws_elasticache_subnet_group.app_cache_subnet_group.name
  security_group_ids            = [aws_security_group.app_sg_1.id]
  num_node_groups               = 1
  replicas_per_node_group       = 2
}

# EKS Cluster and Node Group
resource "aws_eks_cluster" "cluster" {
  name  = "fortunes_cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
    security_group_ids = [aws_security_group.app_sg_1.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs = [ var.my_cidr ]
  }
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager"]
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  instance_types = ["t2.micro"]
  node_group_name = "fortunes-workers"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
  remote_access {
    ec2_ssh_key = "general"
    source_security_group_ids = [aws_security_group.app_sg_1.id, aws_security_group.lb_sg_1.id]
  }
  scaling_config {
    desired_size = 3
    min_size     = 3
    max_size     = 6
  }
  depends_on = [ aws_vpc_security_group_ingress_rule.app_sg_1_ingressrule_cluster, aws_vpc_endpoint.ec2, aws_vpc_endpoint.ecr_api, aws_vpc_endpoint.ecr_dkr, aws_vpc_endpoint.s3, kubernetes_config_map.aws_auth ]
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<-YAML
      - rolearn: ${aws_iam_role.eks_node_role.arn}
        username: system:node:{{EC2PrivateDNSName}}
        groups:
          - system:bootstrappers
          - system:nodes
    YAML
  }

  depends_on = [
    aws_eks_cluster.cluster
  ]
}

# Create the VPC endpoints to take the tasks private

# Define VPC Endpoint for RDS
resource "aws_vpc_endpoint" "rds_endpoint" {
  vpc_id              = aws_vpc.app_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.rds"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.app_sg_1.id]
  subnet_ids          = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]

  private_dns_enabled = true
}

# VPC Endpoints
#
# CloudWatch
resource "aws_vpc_endpoint" "cloudwatch_endpoint" {
  vpc_id              = aws_vpc.app_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.app_sg_1.id]
  subnet_ids          = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]

  private_dns_enabled = true
}

# ECR
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.app_vpc.id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.app_subnet_1.id,aws_subnet.app_subnet_2.id,aws_subnet.app_subnet_3.id]
  private_dns_enabled = true
  security_group_ids = [aws_security_group.app_sg_1.id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.app_vpc.id
  service_name      = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.app_subnet_1.id,aws_subnet.app_subnet_2.id,aws_subnet.app_subnet_3.id]
  private_dns_enabled = true
  security_group_ids = [aws_security_group.app_sg_1.id]
}

# S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.app_vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.app_private_route_table.id]
}

# STS
resource "aws_vpc_endpoint" "sts" {
  vpc_id            = aws_vpc.app_vpc.id
  service_name      = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
  private_dns_enabled = true
  security_group_ids = [aws_security_group.app_sg_1.id]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "*",
        Effect = "Allow",
        Resource = "*",
        Principal = "*"
      }
    ]
  })
}

# EC2
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.app_vpc.id
  service_name      = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
  private_dns_enabled = true
  security_group_ids = [aws_security_group.app_sg_1.id]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "*",
        Effect = "Allow",
        Resource = "*",
        Principal = "*"
      }
    ]
  })
}

# SecretsManager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.app_vpc.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.app_sg_1.id]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "*",
        Effect = "Allow",
        Resource = "*",
        Principal = "*"
      }
    ]
  })
}
