
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

# assign ec2 instance with required permissions

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
          {
            Action  = "sts:AssumeRole"
            Effect  = "Allow"
            Sid     = ""
            Principal = {
                Service = "ec2.amazonaws.com"
            }
          },

      ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy", "arn:aws:iam::aws:policy/AmazonSSMFullAccess", "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess"]
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "iam_webserver_v2"
  role = aws_iam_role.ec2_role.id
}

# Lambda role
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "lambda_rds_execute_statement_policy"

    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Action   = [
            "rds-data:BatchExecuteStatement",
            "rds-data:ExecuteStatement"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSLambdaExecute",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
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

# Route Table. Simple route only to lb. db and instances will share subnets.

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

# Security Groups. Basically trust itself and the lb or app sg
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

# create Aurora and 3 instances, Aurora Serverless v2
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

# Lambda provision our two tables

resource "aws_lambda_function" "lambda_config_db" {
  filename      = "lambda_function.zip"
  function_name = "aurora_config_tables"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "lambda_function.lambda_handler"
  vpc_config {
    security_group_ids = [aws_security_group.app_sg_1.id]
    subnet_ids = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
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

output "result_entry" {
  value = jsondecode(aws_lambda_invocation.lambda_execute.result)
}

# simple load balancer to route 80 -> webserver
resource "aws_lb" "app_load_balancer" {
  name               = "webserver-v3-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg_1.id]
  subnets            = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
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

# Make a launch template from the AMI captured from webserver_v2

resource "aws_launch_template" "app_launch_template" {
  name_prefix   = "webserverr_v3_"
  description   = "version 1 of webserver_v3"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile.arn
  }

  vpc_security_group_ids = [aws_security_group.app_sg_1.id]
  user_data = base64encode(<<-EOF
    #!/bin/bash -xe
          for file in /var/www/html/*.php; do
            sed -i "s/<DB_WRITER_ENDPOINT>/${aws_rds_cluster.app_db_cluster_1.endpoint}/g" "$file"
            sed -i "s/<DB_READER_ENDPOINT>/${aws_rds_cluster.app_db_cluster_1.endpoint}/g" "$file"
            sed -i "s/<DB_USERNAME>/${local.db_creds.db_root_user}/g" "$file"
            sed -i "s/<DB_PASSWORD>/${local.db_creds.db_root_pass}/g" "$file"
            sed -i "s/<UsersTableName>/users/g" "$file"
            sed -i "s/<AppTableName>/fortunes/g" "$file"
            sed -i "s/<DB_NAME>/${var.db_name}/g" "$file"
          done
          chown -R ec2-user:apache /var/www
          chmod 2775 /var/www
          find /var/www -type d -exec chmod 2775 {} \;
          find /var/www -type f -exec chmod 0664 {} \;
    systemctl enable httpd
    systemctl start httpd
    EOF
  )
  tag_specifications {
    resource_type = "instance"

    tags = {
      "Name" = "webserver_v3"
    }
  }
}

# ASG and Target Group
resource "aws_lb_target_group" "app_target_group_http" {
  name     = "${var.project_name}-${var.environment}-targetGroupHTTP"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id
  target_type = "instance"
  stickiness {
    enabled = true
    type = "lb_cookie"
  }
  health_check {
    enabled = true
    healthy_threshold = 3
    interval = 10
    matcher = "200"
    path = "/login.php"
    port = 80
    protocol = "HTTP"
    timeout = 5
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_group" "app_autoscaling_group" {
  desired_capacity     = 3
  max_size             = 6
  min_size             = 3
  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = aws_launch_template.app_launch_template.latest_version
  }
  vpc_zone_identifier  = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
  target_group_arns    = [aws_lb_target_group.app_target_group_http.arn]
  tag {
    key                 = "Name"
    value               = "app_security_group_${local.name_suffix}"
    propagate_at_launch = true
  }

}
