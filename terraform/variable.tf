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

# Variables
variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "dkim_security"
}

variable "subnet_id" {
  description = "Subnet ID for EMR cluster"
  type        = string
  default     = "dkim_subnet"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "dkim_vpc"
}
