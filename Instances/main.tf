provider "aws" {
  region = "us-east-1"
}

# Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create a new VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "172.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Custom_VPC"
  }
}

# Create a Public Subnet in the new VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "172.168.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public_Subnet"
  }
}

# Create an Internet Gateway and attach it to the custom VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "Internet_Gateway"
  }
}

# Create a Route Table for the public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public_Route_Table"
  }
}

# Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "EC2_Security_Group"
  description = "Allow SSH, HTTP, and custom ports"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 8081"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 8082"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 8083"
    from_port   = 8083
    to_port     = 8083
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
    Name = "EC2_SG"
  }
}

# Create an EC2 Key Pair
resource "aws_key_pair" "ec2_key" {
  key_name   = "CLO835_Assignment01"
  public_key = file("CLO835_Assignment01.pub")
}

# Create an EC2 instance
resource "aws_instance" "ec2_instance" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ec2_key.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "CLO835_EC2_Instance"
  }
}

# Create an Elastic IP for the EC2 instance
resource "aws_eip" "static_eip" {
  instance = aws_instance.ec2_instance.id

  tags = {
    Name = "EC2_Static_EIP"
  }
}

# Create ECR Repository for App
resource "aws_ecr_repository" "app_repo" {
  name = "clo835_app"

  tags = {
    Name = "CLO835_App_Repo"
  }
}

# Create ECR Repository for SQL
resource "aws_ecr_repository" "sql_repo" {
  name = "clo835_sql"

  tags = {
    Name = "CLO835_SQL_Repo"
  }
}
