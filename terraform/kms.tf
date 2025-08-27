# KMS 키 생성
resource "aws_kms_key" "dkim_kms_key" {
  description         = "KMS key for DKIM S3 bucket encryption"
  key_usage           = "ENCRYPT_DECRYPT"
  enable_key_rotation = true

  # KMS 키 정책
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "Allow MWAA Service"
        Effect = "Allow"
        Principal = {
          Service = "airflow-env.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "DKIM-KMS-Key"
    Environment = "DEV"
    Purpose     = "S3-SSE"
  }
}

# KMS 키 별칭 생성
resource "aws_kms_alias" "dkim_kms_key_alias" {
  name          = "alias/dkim-kms-key"
  target_key_id = aws_kms_key.dkim_kms_key.key_id
}

# S3 버킷 생성
resource "aws_s3_bucket" "encrypted_bucket" {
  bucket        = "my-encrypted-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = false

  tags = {
    Name        = "Encrypted Bucket"
    Environment = "DEV"
  }
}

# 랜덤 ID 생성 (버킷 이름 충돌 방지)
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 버킷 서버 사이드 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.encrypted_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.dkim_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true # S3 버킷 키 사용 (비용 절약)
  }
}

# S3 버킷 버저닝 설정
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.encrypted_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "bucket_pab" {
  bucket = aws_s3_bucket.encrypted_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 버킷 정책 (선택사항 - 추가 보안)
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.encrypted_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.encrypted_bucket.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption"                = "aws:kms"
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.dkim_kms_key.arn
          }
        }
      },
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.encrypted_bucket.arn,
          "${aws_s3_bucket.encrypted_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# 출력값
output "kms_key_id" {
  description = "KMS Key ID"
  value       = aws_kms_key.dkim_kms_key.id
}

output "kms_key_arn" {
  description = "KMS Key ARN"
  value       = aws_kms_key.dkim_kms_key.arn
}

output "kms_alias" {
  description = "KMS Key Alias"
  value       = aws_kms_alias.dkim_kms_key_alias.name
}

output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.encrypted_bucket.id
}

output "s3_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.encrypted_bucket.arn
}

# 기존 MWAA 버킷이 있다면 이 방식으로 암호화 설정
# resource "aws_s3_bucket_server_side_encryption_configuration" "mwaa_bucket_encryption" {
#   bucket = "dkim-mwaa"  # 기존 버킷 이름
#
#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.dkim_kms_key.arn
#       sse_algorithm     = "aws:kms"
#     }
#     bucket_key_enabled = true
#   }
# }