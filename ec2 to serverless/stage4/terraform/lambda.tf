# a pymysql layer to be used in subsequent lambdas executing sql queries
resource "aws_lambda_layer_version" "pymysql" {
  filename   = "../lambda/layer.zip"
  layer_name = "pymysql_layer"
  compatible_runtimes = ["python3.10"]
}
# Lambda provision our two tables

resource "aws_lambda_function" "lambda_config_db" {
  filename      = "../lambda/aurora_config/lambda_function.zip"
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


# lambda for register
resource "aws_lambda_function" "lambda_fortunes_register" {
  filename      = "../lambda/lambda_fortunes_register/lambda_function.zip"
  function_name = "fortunes_register2"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "lambda_function.lambda_handler"
  layers        = [aws_lambda_layer_version.pymysql.arn]
  environment {
    variables = {
      client_secret   = local.cog_creds.client_secret
    }
  }
}

# lambda for login
resource "aws_lambda_function" "lambda_fortunes_login" {
  filename      = "../lambda/lambda_fortunes_login/lambda_function.zip"
  function_name = "fortunes_login2"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "lambda_function.lambda_handler"
  layers        = [aws_lambda_layer_version.pymysql.arn]
  environment {
    variables = {
      client_secret   = local.cog_creds.client_secret
    }
  }
}

# lambda for submitting fortunes
# VPC Endpoints
resource "aws_lambda_function" "lambda_fortunes_submit" {
  filename      = "../lambda/lambda_fortunes_submit/lambda_function.zip"
  function_name = "fortunes_submit2"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "lambda_function.lambda_handler"
  layers        = [aws_lambda_layer_version.pymysql.arn]
  vpc_config {
    security_group_ids = [aws_security_group.app_sg_1.id]
    subnet_ids = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
  }
  environment {
    variables = {
      RDS_ENDPOINT     = aws_rds_cluster.app_db_cluster_1.endpoint
      DB_NAME     = "fortunes"
      DB_USER     = local.db_creds.db_root_user
      DB_PASSWORD = local.db_creds.db_root_pass
    }
  }
}

# lambda for retrieving fortunes
# VPC Endpoints
resource "aws_lambda_function" "lambda_fortunes_retrieve" {
  filename      = "../lambda/lambda_fortunes_retrieve/lambda_function.zip"
  function_name = "fortunes_retrieve2"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "lambda_function.lambda_handler"
  layers        = [aws_lambda_layer_version.pymysql.arn]
  vpc_config {
    security_group_ids = [aws_security_group.app_sg_1.id]
    subnet_ids = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id, aws_subnet.app_subnet_3.id]
  }
  environment {
    variables = {
      RDS_ENDPOINT  = aws_rds_cluster.app_db_cluster_1.endpoint
      DB_NAME       = "fortunes"
      DB_USER       = local.db_creds.db_root_user
      DB_PASSWORD   = local.db_creds.db_root_pass
    }
  }
}

# lambda for logout
resource "aws_lambda_function" "lambda_fortunes_logout" {
  filename      = "../lambda/lambda_fortunes_logout/lambda_function.zip"
  function_name = "fortunes_logout2"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "lambda_function.lambda_handler"
  layers        = [aws_lambda_layer_version.pymysql.arn]
  environment {
    variables = {
      client_secret   = local.cog_creds.client_secret
    }
  }
}
