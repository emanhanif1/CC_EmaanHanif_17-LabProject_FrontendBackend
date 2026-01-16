provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.env_prefix}-rt"
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "${var.env_prefix}-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
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
    Name = "${var.env_prefix}-sg"
  }
}
resource "aws_instance" "frontend" {
ami = "ami-07ff62358b87c7116"

  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.lab_key.key_name


  tags = {
    Name = "${var.env_prefix}-frontend"
  }
}

resource "aws_key_pair" "lab_key" {
  key_name   = "cc-lab-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_instance" "backend" {
  count                  = 3
  ami                    = "ami-07ff62358b87c7116"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.lab_key.key_name

  tags = {
    Name = "${var.env_prefix}-backend-${count.index + 1}"
  }
}
# 1. Automatically generate the inventory file
resource "local_file" "ansible_inventory" {
  content = <<-EOT
[frontend]
${aws_instance.frontend.public_ip}

[backends]
%{ for ip in aws_instance.backend.*.public_ip ~}
${ip}
%{ endfor ~}

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT
  filename = "${path.module}/ansible/inventory/hosts"
}

# 2. Automatically trigger the Ansible Playbook
resource "null_resource" "ansible_config" {
  triggers = {
    # This ensures it re-runs if instances are replaced
    instance_ids = join(",", concat([aws_instance.frontend.id], aws_instance.backend.*.id))
  }

  # Wait for the instances and the inventory file to be ready
  depends_on = [
    aws_instance.frontend, 
    aws_instance.backend, 
    local_file.ansible_inventory
  ]

  provisioner "local-exec" {
    # The sleep gives AWS 30 seconds to finish booting the OS so SSH is ready
    command = "sleep 30 && cd ansible && export ANSIBLE_CONFIG=./ansible.cfg && ansible-playbook site.yml"
  }
}