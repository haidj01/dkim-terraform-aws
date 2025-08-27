# S3 버킷 생성
resource "aws_s3_bucket" "mwaa_bucket" {
  bucket = "dkim-mwaa"

  tags = {
    Name        = "DKIM MWAA Bucket"
    Environment = "production"
    Purpose     = "MWAA"
  }
}

# S3 버킷 버저닝 설정
resource "aws_s3_bucket_versioning" "mwaa_bucket_versioning" {
  bucket = aws_s3_bucket.mwaa_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "mwaa_bucket_pab" {
  bucket = aws_s3_bucket.mwaa_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS 암호화 설정 (선택사항 - 이전 KMS 키 사용)
resource "aws_s3_bucket_server_side_encryption_configuration" "mwaa_bucket_encryption" {
  bucket = aws_s3_bucket.mwaa_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.dkim_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# dags 폴더 생성 (폴더 구조를 위한 더미 객체)
resource "aws_s3_object" "dags_folder" {
  bucket  = aws_s3_bucket.mwaa_bucket.id
  key     = "dags/"
  content = ""

  tags = {
    Name = "DAGs Folder"
  }
}

# plugins.zip 파일 업로드
resource "aws_s3_object" "plugins_zip" {
  bucket = aws_s3_bucket.mwaa_bucket.id
  key    = "plugins.zip"
  source = "../resource/plugins.zip" # 로컬 파일 경로
  //etag   = filemd5("../resource/plugins.zip") # 파일 변경 감지

  # KMS 암호화 (선택사항)
  kms_key_id             = aws_kms_key.dkim_kms_key.arn
  server_side_encryption = "aws:kms"

  tags = {
    Name = "MWAA Plugins"
  }

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.mwaa_bucket_encryption]
}

# requirements.txt 파일 업로드
resource "aws_s3_object" "requirements_txt" {
  bucket = aws_s3_bucket.mwaa_bucket.id
  key    = "requirements.txt"
  source = "../resource/requirements.txt" # 로컬 파일 경로
  // etag   = filemd5("../resource/requirements.txt") # 파일 변경 감지

  # KMS 암호화 (선택사항)
  kms_key_id             = aws_kms_key.dkim_kms_key.arn
  server_side_encryption = "aws:kms"

  tags = {
    Name = "MWAA Requirements"
  }

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.mwaa_bucket_encryption]
}

//# 샘플 DAG 파일 업로드 (선택사항)
//resource "aws_s3_object" "sample_dag" {
//  bucket = aws_s3_bucket.mwaa_bucket.id
//  key    = "dags/sample_dag.py"
//  content = file("dags/sample_dag.py")  # 로컬 DAG 파일
//  etag   = filemd5("dags/sample_dag.py")
//
//  # KMS 암호화 (선택사항)
//  kms_key_id                = aws_kms_key.dkim_kms_key.arn
//  server_side_encryption    = "aws:kms"
//
//  tags = {
//    Name = "Sample DAG"
//  }
//
//  depends_on = [aws_s3_object.dags_folder]
//}

//# 여러 DAG 파일을 한번에 업로드
//resource "aws_s3_object" "dag_files" {
//  for_each = fileset("dags/", "*.py")
//
//  bucket = aws_s3_bucket.mwaa_bucket.id
//  key    = "dags/${each.value}"
//  source = "dags/${each.value}"
//  etag   = filemd5("dags/${each.value}")
//
//  # KMS 암호화 (선택사항)
//  kms_key_id                = aws_kms_key.dkim_kms_key.arn
//  server_side_encryption    = "aws:kms"
//
//  tags = {
//    Name = "DAG File: ${each.value}"
//  }
//
//  depends_on = [aws_s3_object.dags_folder]
//}

# 출력값
output "mwaa_bucket_name" {
  description = "MWAA S3 Bucket Name"
  value       = aws_s3_bucket.mwaa_bucket.id
}

output "mwaa_bucket_arn" {
  description = "MWAA S3 Bucket ARN"
  value       = aws_s3_bucket.mwaa_bucket.arn
}

//output "plugins_zip_version" {
//  description = "Plugins ZIP file version"
//  value       = aws_s3_object.plugins_zip.version_id
//}

//output "requirements_txt_version" {
//  description = "Requirements.txt file version"
//  value       = aws_s3_object.requirements_txt.version_id
//}