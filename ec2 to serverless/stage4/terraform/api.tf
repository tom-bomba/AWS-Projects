# Create a REST API and the resources the match the lambdas
resource "aws_api_gateway_rest_api" "fortunes_api" {
  name          = "fortunes-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "api_cognito_authorizer" {
  name            = "fortunes-user-pool"
  type            = "COGNITO_USER_POOLS"
  rest_api_id     = aws_api_gateway_rest_api.fortunes_api.id
  provider_arns   = [var.cognito_pool_arn]
}

# /register
resource "aws_api_gateway_resource" "register_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.fortunes_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.fortunes_api.root_resource_id}"
  path_part   = "register"
}

resource "aws_lambda_permission" "register_lambda_permission" {
  statement_id  = "AllowRegisterInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "fortunes_register2"
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.fortunes_api.execution_arn}/*"
}

resource "aws_api_gateway_method" "register_api_method_post" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  resource_id   = aws_api_gateway_resource.register_api_resource.id
  http_method   = "POST" 
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "register_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.fortunes_api.id
  resource_id             = aws_api_gateway_resource.register_api_resource.id
  http_method             = aws_api_gateway_method.register_api_method_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_fortunes_register.invoke_arn
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}


resource "aws_api_gateway_method" "register_api_method_options" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  resource_id   = aws_api_gateway_resource.register_api_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "register_OptionsMethodIntegration" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.register_api_resource.id
  http_method = aws_api_gateway_method.register_api_method_options.http_method
  passthrough_behavior = "WHEN_NO_MATCH"
  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_method_response" "register_Options200Response" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.register_api_resource.id
  http_method = aws_api_gateway_method.register_api_method_options.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
  }
}

resource "aws_api_gateway_integration_response" "register_OptionsMethodIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.register_api_resource.id
  http_method = aws_api_gateway_method.register_api_method_options.http_method
  status_code = aws_api_gateway_method_response.register_Options200Response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
resource "aws_api_gateway_method_response" "register_post_200_response" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.register_api_resource.id
  http_method = aws_api_gateway_method.register_api_method_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}
# /login
resource "aws_api_gateway_resource" "login_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.fortunes_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.fortunes_api.root_resource_id}"
  path_part   = "login"
}

resource "aws_lambda_permission" "login_lambda_permission" {
  statement_id  = "AllowLoginInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "fortunes_login2"
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.fortunes_api.execution_arn}/*"
}

resource "aws_api_gateway_method" "login_api_method_post" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  resource_id   = aws_api_gateway_resource.login_api_resource.id
  http_method   = "POST" 
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "login_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.fortunes_api.id
  resource_id             = aws_api_gateway_resource.login_api_resource.id
  http_method             = aws_api_gateway_method.login_api_method_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_fortunes_login.invoke_arn
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}
resource "aws_api_gateway_method_response" "login_post_200_response" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.login_api_resource.id
  http_method = aws_api_gateway_method.login_api_method_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}
resource "aws_api_gateway_method" "login_api_method_options" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  resource_id   = aws_api_gateway_resource.login_api_resource.id
  authorization = "NONE"
  http_method   = "OPTIONS"
}

resource "aws_api_gateway_integration" "login_OptionsMethodIntegration" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.login_api_resource.id
  http_method = aws_api_gateway_method.login_api_method_options.http_method
  passthrough_behavior = "WHEN_NO_MATCH"
  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_method_response" "login_Options200Response" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.login_api_resource.id
  http_method = aws_api_gateway_method.login_api_method_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
  }
}

resource "aws_api_gateway_integration_response" "login_OptionsMethodIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.login_api_resource.id
  http_method = aws_api_gateway_method.login_api_method_options.http_method
  status_code = aws_api_gateway_method_response.login_Options200Response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

}

# /submit
resource "aws_api_gateway_resource" "submit_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.fortunes_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.fortunes_api.root_resource_id}"
  path_part   = "submit"
}

resource "aws_lambda_permission" "submit_lambda_permission" {
  statement_id  = "AllowSubmitInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "fortunes_submit2"
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.fortunes_api.execution_arn}/*"
}

resource "aws_api_gateway_method" "submit_api_method_post" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  resource_id   = aws_api_gateway_resource.submit_api_resource.id
  http_method   = "POST" 
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.api_cognito_authorizer.id
}

resource "aws_api_gateway_integration" "submit_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.fortunes_api.id
  resource_id             = aws_api_gateway_resource.submit_api_resource.id
  http_method             = aws_api_gateway_method.submit_api_method_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_fortunes_submit.invoke_arn
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_method" "submit_api_method_options" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  resource_id   = aws_api_gateway_resource.submit_api_resource.id
  authorization = "NONE"
  http_method   = "OPTIONS"
}

resource "aws_api_gateway_integration" "submit_OptionsMethodIntegration" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.submit_api_resource.id
  http_method = aws_api_gateway_method.submit_api_method_options.http_method
  passthrough_behavior = "WHEN_NO_MATCH"
  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}
resource "aws_api_gateway_method_response" "submit_post_200_response" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.submit_api_resource.id
  http_method = aws_api_gateway_method.submit_api_method_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}
resource "aws_api_gateway_method_response" "submit_Options200Response" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.submit_api_resource.id
  http_method = aws_api_gateway_method.submit_api_method_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
  }
}

resource "aws_api_gateway_integration_response" "submit_OptionsMethodIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.submit_api_resource.id
  http_method = aws_api_gateway_method.submit_api_method_options.http_method
  status_code = aws_api_gateway_method_response.submit_Options200Response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

}

# /retrieve
resource "aws_api_gateway_resource" "retrieve_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.fortunes_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.fortunes_api.root_resource_id}"
  path_part   = "retrieve"
}

resource "aws_lambda_permission" "retrieve_lambda_permission" {
  statement_id  = "AllowRetrieveInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "fortunes_retrieve2"
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.fortunes_api.execution_arn}/*"
}

resource "aws_api_gateway_method" "retrieve_api_method_post" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  resource_id   = aws_api_gateway_resource.retrieve_api_resource.id
  http_method   = "POST" 
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.api_cognito_authorizer.id
}

resource "aws_api_gateway_integration" "retrieve_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.fortunes_api.id
  resource_id             = aws_api_gateway_resource.retrieve_api_resource.id
  http_method             = aws_api_gateway_method.retrieve_api_method_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_fortunes_retrieve.invoke_arn
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_method" "retrieve_api_method_options" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  resource_id   = aws_api_gateway_resource.retrieve_api_resource.id
  authorization = "NONE"
  http_method   = "OPTIONS"
}

resource "aws_api_gateway_integration" "retrieve_OptionsMethodIntegration" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.retrieve_api_resource.id
  http_method = aws_api_gateway_method.retrieve_api_method_options.http_method
  passthrough_behavior = "WHEN_NO_MATCH"
  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_method_response" "retrieve_Options200Response" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.retrieve_api_resource.id
  http_method = aws_api_gateway_method.retrieve_api_method_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
  }
}

resource "aws_api_gateway_integration_response" "retrieve_OptionsMethodIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.retrieve_api_resource.id
  http_method = aws_api_gateway_method.retrieve_api_method_options.http_method
  status_code = aws_api_gateway_method_response.retrieve_Options200Response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  }
resource "aws_api_gateway_method_response" "retrieve_post_200_response" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.retrieve_api_resource.id
  http_method = aws_api_gateway_method.retrieve_api_method_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}
# /logout
resource "aws_api_gateway_resource" "logout_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.fortunes_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.fortunes_api.root_resource_id}"
  path_part   = "logout"
}

resource "aws_lambda_permission" "logout_lambda_permission" {
  statement_id  = "AllowLogoutInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "fortunes_logout2"
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.fortunes_api.execution_arn}/*"
}

resource "aws_api_gateway_method" "logout_api_method_post" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  resource_id   = aws_api_gateway_resource.logout_api_resource.id
  http_method   = "POST" 
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.api_cognito_authorizer.id
}

resource "aws_api_gateway_integration" "logout_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.fortunes_api.id
  resource_id             = aws_api_gateway_resource.logout_api_resource.id
  http_method             = aws_api_gateway_method.logout_api_method_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_fortunes_logout.invoke_arn
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_method" "logout_api_method_options" {
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  resource_id   = aws_api_gateway_resource.logout_api_resource.id
  authorization = "NONE"
  http_method   = "OPTIONS"
}

resource "aws_api_gateway_integration" "logout_OptionsMethodIntegration" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.logout_api_resource.id
  http_method = aws_api_gateway_method.logout_api_method_options.http_method
  passthrough_behavior = "WHEN_NO_MATCH"
  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_method_response" "logout_Options200Response" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.logout_api_resource.id
  http_method = aws_api_gateway_method.logout_api_method_options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
  }
}

resource "aws_api_gateway_integration_response" "logout_OptionsMethodIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.logout_api_resource.id
  http_method = aws_api_gateway_method.logout_api_method_options.http_method
  status_code = aws_api_gateway_method_response.logout_Options200Response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
resource "aws_api_gateway_method_response" "logout_post_200_response" {
  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  resource_id = aws_api_gateway_resource.logout_api_resource.id
  http_method = aws_api_gateway_method.logout_api_method_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}
resource "aws_api_gateway_stage" "test_stage" {
  depends_on = [aws_api_gateway_deployment.api_dev_deployment]
  deployment_id = aws_api_gateway_deployment.api_dev_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.fortunes_api.id
  stage_name    = "test7"
}

resource "aws_api_gateway_deployment" "api_dev_deployment" {
  depends_on = [
    aws_api_gateway_integration.logout_OptionsMethodIntegration,
    aws_api_gateway_integration.retrieve_OptionsMethodIntegration,
    aws_api_gateway_integration.submit_OptionsMethodIntegration,
    aws_api_gateway_integration.login_OptionsMethodIntegration,
    aws_api_gateway_integration.register_OptionsMethodIntegration,
    aws_api_gateway_integration.submit_api_integration,
    aws_api_gateway_integration.login_api_integration,
    aws_api_gateway_integration.retrieve_api_integration,
    aws_api_gateway_integration.logout_api_integration,
    aws_api_gateway_integration.register_api_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.fortunes_api.id
  stage_name  = "test5"
  description = "Deployed at ${timestamp()}"
  lifecycle {
    create_before_destroy = true
  }
}


resource "null_resource" "fix_js" {
  provisioner "local-exec" {
    command = "sed -i 's#<API_ENDPOINT>#${aws_api_gateway_deployment.api_dev_deployment.invoke_url}#g' ../webserver/app.js"
  }
  depends_on = [aws_api_gateway_deployment.api_dev_deployment]
}
