terraform{
    required_version = ">= 1.0.0"
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
}

provider "aws" {
  region = "us-east-1"
}


data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function_payload.zip"
}


resource "aws_iam_role" "lambda_role" {
    name = "security_notifier_lambda_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "security_notifier" {
    filename = data.archive_file.lambda_zip.output_path
    function_name = "security_notifier_lambda"
    role = aws_iam_role.lambda_role.arn
    handler = "lambda_function.lambda_function"
    runtime = "python3.11"
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    
    environment {
        variables = {
          DISCORD_WEBHOOK_URL = var.DISCORD_WEBHOOK_URL 
        }
    }
}

resource "aws_cloudwatch_event_rule" "security_event_rule" {
    name = "security-notifier-rule"
    description = "Wykrywa kluczowe akcje w koncie AWS"

    event_pattern = jsonencode({
        source = ["aws.iam", "aws.s3"]
    })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
    rule = aws_cloudwatch_event_rule.security_event_rule.name
    target_id = "SendToDiscordLambda"
    arn = aws_lambda_function.security_notifier.arn  
}

resource "aws_lambda_permission" "allow_eventbridge" {
    statement_id  = "AllowExecutionFromEventBridge"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.security_notifier.function_name
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.security_event_rule.arn
}

data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "security_trail" {
  name = "security-notifier-trail"
  s3_bucket_name = aws_s3_bucket.trail_bucket.id
  include_global_service_events = true
  is_multi_region_trail = true
  enable_logging = true
}

resource "aws_s3_bucket" "trail_bucket" {
  bucket        = "security-notifier-trail-logs-${data.aws_caller_identity.current.account_id}-us"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "trail_bucket_block" {
  bucket = aws_s3_bucket.trail_bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "trail_bucket_policy" {
  bucket = aws_s3_bucket.trail_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.trail_bucket.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.trail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}