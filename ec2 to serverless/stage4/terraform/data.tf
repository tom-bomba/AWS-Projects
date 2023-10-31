data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "amzn-linux-ami" {  
   name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_secretsmanager_secret_version" "db_secrets" {
  secret_id = "dev/db_creds/webserver_v2"
}
data "aws_secretsmanager_secret_version" "cognito_secrets" {
  secret_id = "dev/cognito/fortunes"
}
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid    = "SourceIP"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.bucket_webserver_v4.arn,
      "${aws_s3_bucket.bucket_webserver_v4.arn}/*"
    ]

    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"

      values = [
        var.my_cidr,
      ]
    }
  }
  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket_webserver_v4.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
  }
  }
}

data "aws_iam_policy_document" "cognito_policy" {
  statement {
    actions = [
      "cognito-idp:*",
      "cognito-identity:*"
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "api_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = [aws_api_gateway_rest_api.fortunes_api.execution_arn]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = [var.my_cidr]
    }
  }
}