# MWAA Execution Role with correct service principal
resource "aws_iam_role" "mwaa_execution_role" {
  name = "mwaa-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "airflow-env.amazonaws.com" # Fixed: was mwaa.amazonaws.com
        }
      },
    ]
  })
}

# Custom policy for MWAA execution role
resource "aws_iam_role_policy" "mwaa_execution_policy" {
  name = "mwaa-execution-policy"
  role = aws_iam_role.mwaa_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "airflow:PublishMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = "s3:ListAllMyBuckets"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:List*"
        ]
        Resource = [
          "${aws_s3_bucket.mwaa_bucket.arn}",
          "${aws_s3_bucket.mwaa_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:airflow-*",
          "arn:aws:logs:*:*:log-group:airflow-*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ]
        Resource = "arn:aws:sqs:*:*:airflow-celery-*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:Encrypt"
        ]
        NotResource = "arn:aws:kms:*:*:key/*"
        Condition = {
          StringLike = {
            "kms:ViaService" = [
              "sqs.*.amazonaws.com",
              "s3.*.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

//# Attach the custom policy to the role
//resource "aws_iam_role_policy_attachment" "mwaa_execution_policy_attachment" {
//  role       = aws_iam_role.mwaa_execution_role.name
//  policy_arn = aws_iam_role_policy.mwaa_execution_policy
//}

//# Data sources for dynamic values
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Example S3 bucket reference (adjust to your bucket)
//resource "aws_s3_bucket" "mwaa_bucket" {
//  bucket = "your-mwaa-bucket-name"
//}

# Alternative: Use AWS managed policy for MWAA service role (simpler approach)
//resource "aws_iam_role_policy_attachment" "mwaa_service_role_policy" {
//  role       = aws_iam_role.mwaa_execution_role.name
//  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonMWAAServiceRolePolicy"
//}

# Output the role ARN for use in MWAA environment
output "mwaa_execution_role_arn" {
  value = aws_iam_role.mwaa_execution_role.arn
}