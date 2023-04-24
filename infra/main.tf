terraform {
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

# the locals block is used to declare constants that 
# you can use throughout your code
locals {
  function_name_get = "get-obituaries-30142672"
  function_name_create = "create-obituary-30142672"
  handler_name  = "main.lambda_handler"
  artifact_name_get = "${local.function_name_get}/artifact.zip"
  artifact_name_create = "${local.function_name_create}/artifact.zip"
}

# create a role for the Lambda function to assume
# every service on AWS that wants to call other AWS services should first assume a role and
# then any policy attached to the role will give permissions
# to the service so it can interact with other AWS services
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "lambda" {
  name               = "iam-for-lambda-obituaries"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


# create archive file from main.py
data "archive_file" "lambda-get-zip" {
  type = "zip"
  # this file (main.py) needs to exist in the same folder as this 
  # Terraform configuration file
  source_file = "../functions/get-obituaries/main.py"
  output_path = local.artifact_name_get
}

# create archive file from main.py
data "archive_file" "lambda-create-zip" {
  type = "zip"
  # this file (main.py) needs to exist in the same folder as this 
  # Terraform configuration file
  source_dir = "../functions/create-obituary"
  output_path = local.artifact_name_create
}


# create a Lambda function
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
resource "aws_lambda_function" "lambda-create-obituary" {
  role             = aws_iam_role.lambda.arn
  function_name    = local.function_name_create
  handler          = local.handler_name
  filename         = local.artifact_name_create
  source_code_hash = data.archive_file.lambda-create-zip.output_base64sha256
  timeout = 20

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}

# create a Lambda function
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
resource "aws_lambda_function" "lambda-get-obituaries" {
  role             = aws_iam_role.lambda.arn
  function_name    = local.function_name_get
  handler          = local.handler_name
  filename         = local.artifact_name_get
  source_code_hash = data.archive_file.lambda-get-zip.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}

# create a policy for publishing logs to CloudWatch
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "logs" {
  name        = "lambda-logging-obituaries"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# attach the above policy to the function role
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.logs.arn
}

# create a Function URL for Lambda 
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url
resource "aws_lambda_function_url" "url-get-obituaries" {
  function_name      = aws_lambda_function.lambda-get-obituaries.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

# create a Function URL for Lambda 
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url
resource "aws_lambda_function_url" "url-create-obituary" {
  function_name      = aws_lambda_function.lambda-create-obituary.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["PUT","POST"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}


# show the Function URL after creation
output "lambda_url_get_obituary" {
  value = aws_lambda_function_url.url-get-obituaries.function_url
}



# show the Function URL after creation
output "lambda_url_create_obituary" {
  value = aws_lambda_function_url.url-create-obituary.function_url
}

resource "aws_dynamodb_table""the-last-show-30141162"{
  name = "the-last-show-30141162"
  billing_mode = "PROVISIONED"

  read_capacity = 1

  write_capacity = 1

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_policy" "ssm_policy" {
  name        = "ssm_policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:ca-central-1:963009025042:parameter/the-last-show/*"
      }
    ]
  })
}

resource "aws_iam_policy" "dynamodb_scan_policy" {
  name        = "dynamodb-scan-policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:Scan",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:ca-central-1:963009025042:table/the-last-show-30141162"
      },
    ]
  })
}

resource "aws_iam_policy" "dynamodb_policy" {
  name = "dynamodb_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = "arn:aws:dynamodb:ca-central-1:963009025042:table/the-last-show-30141162"
      }
    ]
  })
}


resource "aws_iam_policy" "lambda_polly_policy" {
  name = "lambda_polly_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "polly:SynthesizeSpeech"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  policy_arn = aws_iam_policy.ssm_policy.arn
  role       = "iam-for-lambda-obituaries" # replace with the actual name of the IAM role associated with the Lambda function
}

resource "aws_iam_role_policy_attachment" "polly_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_polly_policy.arn
  role       = "iam-for-lambda-obituaries" # replace with the actual name of the IAM role associated with the Lambda function
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy_attachment" {
  policy_arn = aws_iam_policy.dynamodb_policy.arn
  role       = "iam-for-lambda-obituaries" # replace with the actual name of the IAM role associated with the Lambda function
}

resource "aws_iam_role_policy_attachment" "dynamodb_scan_policy_attachment" {
  policy_arn = aws_iam_policy.dynamodb_scan_policy.arn
  role       = "iam-for-lambda-obituaries" # replace with the actual name of the IAM role associated with the Lambda function
}
# two lambda functions w/ function url
# one dynamodb table
# roles and policies as needed
# step functions (if you're going for the bonus marks)
