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
  name_suffix = "${var.project_name}-${var.environment}"
  outputs = jsondecode(file("outputs.json"))
}

# Configure the K8s resources. Templates are loaded in data.tf
resource "kubernetes_manifest" "manifest_main" {
  provider = kubernetes
  manifest = yamldecode(data.template_file.deployment_main.rendered)
}

resource "kubernetes_config_map" "cw_agent_config" {
  metadata {
    name = "cw-agent-config"
  }
  data = {
    "cloudwatch-config.json" = file("${path.module}/cloudwatch-config.json")
  }
}

# Load Balancer
# Handles session stickiness
resource "kubernetes_service" "service" {
  metadata {
    name = "fortunes-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "http"
      "service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout" = "60"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = "http"
      "service.beta.kubernetes.io/aws-load-balancer-type" = "alb"
      "service.beta.kubernetes.io/aws-load-balancer-stickiness-enabled" = "true"
      "service.beta.kubernetes.io/aws-load-balancer-stickiness-ttl" = "600"
    }
  }
  spec {
    selector = {
      App = "fortunes-web"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
    load_balancer_source_ranges = [var.my_cidr]
  }
  
}