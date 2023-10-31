
locals {
    required_tags = {
        project     = var.project_name
        environment = var.environment
    }
    tags = merge(var.resource_tags, local.required_tags)
}

locals {
    name_suffix = "${var.project_name}-${var.environment}"
}

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
    inline_policy {
        name = "ec2_allow_s3read"
        policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
                {
                    Action = ["s3:GetObject", "s3:ListBucket"]
                    Effect = "Allow"
                    Resource = [var.bucket_arn, "${var.bucket_arn}/*"]
                    
                }
            ]
        })
    }
    managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy", "arn:aws:iam::aws:policy/AmazonSSMFullAccess"]

}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "iam_webserver_v2"
    role = aws_iam_role.ec2_role.id
}

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

/*
resource "aws_internet_gateway_attachment" "app_vpc_ig_attachment" {
    internet_gateway_id = aws_internet_gateway.app_vpc_ig.id
    vpc_id              = aws_vpc.app_vpc.id
}
*/

resource "aws_subnet" "app_subnet_1" {
    vpc_id = aws_vpc.app_vpc.id
    availability_zone = data.aws_availability_zones.available.names[0]
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    tags = {
        Name = "app_vpc_subnet_${local.name_suffix}"
    }
}

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

resource "aws_security_group" "app_sg_1" {
    name        = "app_sg_1"
    description = "security group applied to the app webserver"
    vpc_id      = aws_vpc.app_vpc.id
    tags = {
        Name = "app_vpc_security_group_${local.name_suffix}"
    }
}
resource "aws_vpc_security_group_egress_rule" "app_sg_1_egressrule_1" {
  security_group_id = aws_security_group.app_sg_1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

resource "aws_vpc_security_group_ingress_rule" "app_sg_1_ingressrule_1" {
  security_group_id = aws_security_group.app_sg_1.id
  cidr_ipv4         = var.my_cidr
  ip_protocol       = -1
}

resource "aws_instance" "app_webserver_1" {
    ami                     = data.aws_ssm_parameter.amzn-linux-ami.value
    instance_type           = "t2.micro"
    iam_instance_profile    = aws_iam_instance_profile.ec2_instance_profile.name
    subnet_id               = aws_subnet.app_subnet_1.id
    key_name                = var.key_name
    vpc_security_group_ids  = [aws_security_group.app_sg_1.id]
    tags = {
        Name = "app_webserver1_${local.name_suffix}"
    }
}

