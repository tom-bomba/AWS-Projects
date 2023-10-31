
locals {
  required_tags = {
      project     = var.project_name
      environment = var.environment
  }
  tags = merge(var.resource_tags, local.required_tags)
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.db_secrets.secret_string
  )
  subnet_ids = [
    aws_subnet.app_subnet_1.id,
    aws_subnet.app_subnet_2.id,
    aws_subnet.app_subnet_3.id,
  ]
  name_prefix = "${var.project_name}-${var.environment}"
}


# assign ec2 instance with required permissions
resource "aws_iam_policy" "rds_access" {
  name        = "rds_access"
  description = "Policy for RDS read/write access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction",
        ]
        Effect   = "Allow"
        Resource = "${ aws_rds_cluster.app_db_cluster_1.arn }" # *,  Else ARN of your RDS resource if possible
      },
    ]
  })
}

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
      },
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy", # Required for ECS tasks
    aws_iam_policy.rds_access.arn, # Custom policy for RDS access
    aws_iam_policy.cloudwatch_logs_access.arn, # Custom policy for CloudWatch logs
  ]
} 


# Lambda role
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
    "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess", 
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
}


# Make the network resources: 1 vpc, 3 subnets in 3 AZs.
resource "aws_vpc" "app_vpc" {
  cidr_block              = "10.0.0.0/16"
  enable_dns_hostnames    = true
  enable_dns_support      = true
  tags = {
      Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "app_vpc_ig" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
      Name = "${local.name_prefix}-ig"
  }
}

resource "aws_subnet" "app_subnet_1" {
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = "10.0.1.0/24"
  tags = {
      Name = "${local.name_prefix}-subnet1"
  }
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = "10.0.2.0/24"
  tags = {
      Name = "${local.name_prefix}-subnet2"
  }
}

resource "aws_subnet" "app_subnet_3" {
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = data.aws_availability_zones.available.names[2]
  cidr_block = "10.0.3.0/24"
  tags = {
      Name = "${local.name_prefix}-subnet3"
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
      Name = "${local.name_prefix}-route-table"
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
resource "aws_security_group" "lb_sg_1" {
    name        = "lb_sg_1"
    description = "security group applied to the load balancer"
    vpc_id      = aws_vpc.app_vpc.id
    tags = {
        Name = "${local.name_prefix}-lb-sg"
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
resource "aws_security_group" "app_sg_1" {
    name        = "app_sg_1"
    description = "security group applied to the app webserver"
    vpc_id      = aws_vpc.app_vpc.id
    tags = {
        Name = "${local.name_prefix}-app-sg"
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

# create Aurora
resource "aws_db_subnet_group" "app_db_subnet_group_1" {
  name       = "${local.name_prefix}-app_db_subnet_group_1"
  subnet_ids = local.subnet_ids
  tags = {
    Name = "app_db_subnet_group"
  }
}


resource "aws_rds_cluster" "app_db_cluster_1" {
  cluster_identifier        = "${local.name_prefix}-app-db-cluster-1"
  availability_zones        = [data.aws_availability_zones.available.names[0],data.aws_availability_zones.available.names[1],data.aws_availability_zones.available.names[2]] 
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
  identifier         = "${local.name_prefix}-app-aurora-cluster-${count.index}"
  cluster_identifier = aws_rds_cluster.app_db_cluster_1.id
  instance_class     = "db.serverless"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.03.1"

}

# Lambda provision our two tables

resource "aws_lambda_function" "lambda_config_db" {
  filename      = "lambda_function.zip"
  function_name = "${local.name_prefix}-aurora_config_tables"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "lambda_function.lambda_handler"
  vpc_config {
    security_group_ids = [aws_security_group.app_sg_1.id]
    subnet_ids = local.subnet_ids
  }
}
resource "aws_lambda_invocation" "lambda_execute" {
  function_name = aws_lambda_function.lambda_config_db.function_name
  input = jsonencode({
    rds_endpoint = aws_rds_cluster.app_db_cluster_1.endpoint
    db_username = local.db_creds.db_root_user
    db_password = local.db_creds.db_root_pass
  })
  depends_on = [aws_lambda_function.lambda_config_db, aws_rds_cluster_instance.app_cluster_instances, aws_rds_cluster.app_db_cluster_1]
}

# simple load balancer to route 80 -> webserver
resource "aws_lb" "app_load_balancer" {
  name               = "${local.name_prefix}-webserver-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg_1.id]
  subnets            = local.subnet_ids
  ip_address_type    = "ipv4"
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group_http.arn
  }
}
resource "aws_lb_target_group" "app_target_group_http" {
  name     = "${local.name_prefix}-targetGroupHTTP"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id
  target_type = "ip"  # Use "ip" for Fargate tasks

  health_check {
    enabled = true
    healthy_threshold = 3
    interval = 35
    matcher = "200"
    path = "/login.php"
    port = "traffic-port"  # Use "traffic-port" for Fargate tasks
    protocol = "HTTP"
    timeout = 30
    unhealthy_threshold = 2
  }
  stickiness {
    enabled = true
    type = "lb_cookie"
    cookie_duration = 300  # Length of time in seconds to stick with the same target. Adjust to your needs.
  }
}

resource "aws_ecs_cluster" "cluster" {
  name    = "${local.name_prefix}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${local.name_prefix}-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name  = var.my_image_name
      image = var.my_image_uri
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      logConfiguration = {
        logDriver               = "awslogs"
        options = { 
          awslogs-group         = "/ecs/fortunes_web2"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        {
          name  = "DB_WRITER_ENDPOINT"
          value = "${aws_rds_cluster.app_db_cluster_1.endpoint}"
        },
        {
          name  = "DB_READER_ENDPOINT"
          value = "${aws_rds_cluster.app_db_cluster_1.reader_endpoint}"
        },
        {
          name  = "DB_USERNAME"
          value = "${local.db_creds.db_root_user}"
        },
        {
          name  = "DB_PASSWORD"
          value = "${local.db_creds.db_root_pass}"
        },
        {
          name  = "DB_NAME"
          value = "${var.db_name}"
        },
        {
          name  = "UsersTableName"
          value = "${var.db_name}"
        },
        {
          name  = "AppTableName"
          value = "${var.db_name}"
        }
      ]
    }
  ]) 
}
resource "aws_appautoscaling_target" "target" {
  max_capacity       = 6
  min_capacity       = 3
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "${local.name_prefix}-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.target.resource_id
  scalable_dimension = aws_appautoscaling_target.target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 75.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_ecs_service" "service" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets = local.subnet_ids
    security_groups  = [aws_security_group.app_sg_1.id]
    assign_public_ip = false
  }

  desired_count = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group_http.arn
    container_name   = "fortunes-web"
    container_port   = 80
  }

  depends_on = [aws_ecs_task_definition.task]
}

#create the VPC endpoints to take the tasks private

# Define VPC Endpoint for RDS
resource "aws_vpc_endpoint" "rds_endpoint" {
  vpc_id              = aws_vpc.app_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.rds"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.app_sg_1.id]
  subnet_ids          = local.subnet_ids

  private_dns_enabled = true
}

# Define VPC Endpoint for CloudWatch
resource "aws_vpc_endpoint" "cloudwatch_endpoint" {
  vpc_id              = aws_vpc.app_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.app_sg_1.id]
  subnet_ids          = local.subnet_ids

  private_dns_enabled = true
}

# Define VPC Endpoints for ECR
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

#s3 endpoint to allow ecs to access ecr
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.app_vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.app_route_table_1.id]
}
