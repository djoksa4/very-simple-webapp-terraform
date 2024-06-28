terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

################ NETWORK ################

# VPC
resource "aws_vpc" "cicd_vpc1" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name = "cicd-vpc1"
  }
}

# Subnet
resource "aws_subnet" "sn_pub_A" {
  vpc_id                  = aws_vpc.cicd_vpc1.id
  cidr_block              = "10.0.0.64/27"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "sn-pub-A"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "cicd_vpc1_igw" {
  vpc_id = aws_vpc.cicd_vpc1.id

  tags = {
    Name = "cicd-vpc1-igw"
  }
}

# Public Route Table setup
resource "aws_route_table" "cicd_vpc1_rt_pub" {
  vpc_id = aws_vpc.cicd_vpc1.id

  tags = {
    Name = "cicd-vpc1-rt-pub"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cicd_vpc1_igw.id
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "sn_pub_A_assoc" {
  subnet_id      = aws_subnet.sn_pub_A.id
  route_table_id = aws_route_table.cicd_vpc1_rt_pub.id
}


################ INSTANCES ################

# WebApp instance
resource "aws_instance" "webapp_server_instance" {
  ami           = "ami-0005e0cfe09cc9050" # Linux AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.sn_pub_A.id
  private_ip = "10.0.0.87"

  key_name = "A4L"

  vpc_security_group_ids = [aws_security_group.webapp-server-sg.id] # Associate the security group with the instance

  tags = {
    Name = "webapp_server_instance"
  }

  user_data = file("webapp_provision_script.sh")
}


# Security Group for Linux EC2 "webapp_server_instance" instance
resource "aws_security_group" "webapp-server-sg" {
  name        = "webapp-server-sg"
  description = "Security group for Linux EC2 WebApp access"

  vpc_id = aws_vpc.cicd_vpc1.id

  # Inbound rule for web access 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule for SSH (port 22) for EC2 Instance Connect
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule allowing all traffic (for installing apps, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}