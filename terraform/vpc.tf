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


# VPC for EMR
resource "aws_vpc" "main_emr" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dkim_emr_vpc"
  }
}

# Internet Gateway - EMR
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_emr.id

  tags = {
    Name = "dkim_emr_igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main_emr.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "dkim_public_subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main_emr.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "dkim_private_subnet"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_emr.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "dkim_public_rt"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main_emr.id

  tags = {
    Name = "dkim_private_rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Data source for AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Security Group for EMR
resource "aws_security_group" "emr_master" {
  name_prefix = "emr-master-"
  vpc_id      = aws_vpc.main_emr.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "emr-master-sg"
  }
}

resource "aws_security_group" "emr_slave" {
  name_prefix = "emr-slave-"
  vpc_id      = aws_vpc.main_emr.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "emr-slave-sg"
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main_emr.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "emr_master_sg_id" {
  value = aws_security_group.emr_master.id
}

output "emr_slave_sg_id" {
  value = aws_security_group.emr_slave.id
}