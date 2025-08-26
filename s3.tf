resource "aws_s3_bucket" "mwaa_bucket" {
  bucket        = "dkim-mwaa"
  force_destroy = true
  versioning {
    enabled = true
  }
}