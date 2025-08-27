resource "aws_mwaa_environment" "dkim-mwaa" {
  name                 = "dkim-mwaa"
  airflow_version      = "2.10.3" # Specify your desired Airflow version
  environment_class    = "mw1.small"
  source_bucket_arn    = aws_s3_bucket.mwaa_bucket.arn
  dag_s3_path          = "dags/"
  execution_role_arn   = aws_iam_role.mwaa_execution_role.arn
  plugins_s3_path      = "plugins.zip"
  requirements_s3_path = "requirements.txt"

  # Add KMS encryption - use the same key as S3 bucket
  kms_key = aws_kms_key.dkim_kms_key.arn

  network_configuration {
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_group_ids = [aws_security_group.mwaa_security_group.id]
  }

  webserver_access_mode = "PUBLIC_ONLY" # Or "PRIVATE_ONLY" for production

  depends_on = [
    aws_iam_role.mwaa_execution_role,
    aws_iam_role_policy.mwaa_execution_policy
  ]
}
