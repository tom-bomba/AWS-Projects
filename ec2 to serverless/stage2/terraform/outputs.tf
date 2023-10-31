output "tags" {
    value = local.tags
}

output "app_webserver1_pubip" {
    value = aws_instance.app_webserver_1.public_ip
}