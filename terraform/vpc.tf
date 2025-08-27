resource "aws_vpc" "mwaa_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "mwaa-vpc"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Adjust to your region
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Adjust to your region
}

resource "aws_security_group" "mwaa_security_group" {
  name        = "mwaa-sg"
  description = "Security group for MWAA environment"
  vpc_id      = aws_vpc.mwaa_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Restrict as needed for production
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}