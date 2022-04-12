locals {
  jenkins_ingress_rules = [
    {
      port        = 22,
      description = "SSH"
    },
    {
      port        = 8080
      description = "Jenkins HTTP"
    }
  ]
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}

resource "aws_security_group" "linux_sg" {
  name        = "linux_sg"
  description = "SSH access for linux server"
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.cidr_ip]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  tags = {
    Name = "linux_sg"
  }

}

resource "aws_instance" "linux_server" {
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.linux_sg.id]
  ami                    = var.ami_id
  tags = {
    "Name" = "Linux server"
  }
}

resource "null_resource" "status" {
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.linux_server.id} --region us-east-1"
  }
}


resource "aws_vpc" "pluto_vpc" {
  cidr_block       = "10.12.0.0/25"
  instance_tenancy = "default"
  tags = {
    "Name" = "pluto-vpc"
  }
}

resource "aws_internet_gateway" "pluto_igw" {
  vpc_id = aws_vpc.pluto_vpc.id
  tags = {
    "Name" = "pluto-igw"
  }
}

resource "aws_route_table" "pluto_public_rt" {
  vpc_id = aws_vpc.pluto_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pluto_igw.id
  }
  tags = {
    "Name" = "pluto_public_rt"
  }
}

resource "aws_subnet" "pluto_public_subnet_1a" {
  vpc_id                  = aws_vpc.pluto_vpc.id
  cidr_block              = "10.12.0.0/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "pluto-public-1a"
  }
}

resource "aws_subnet" "pluto_public_subnet_1b" {
  vpc_id                  = aws_vpc.pluto_vpc.id
  cidr_block              = "10.12.0.64/26"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "pluto-public-1b"
  }
}

resource "aws_route_table_association" "pluto_public_1a" {
  subnet_id      = aws_subnet.pluto_public_subnet_1a.id
  route_table_id = aws_route_table.pluto_public_rt.id
}

resource "aws_route_table_association" "pluto_public_1b" {
  subnet_id      = aws_subnet.pluto_public_subnet_1b.id
  route_table_id = aws_route_table.pluto_public_rt.id
}

resource "aws_ecr_repository" "pluto_ecr" {
  name = "pluto-app"
}


resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Jenkins SG"
  vpc_id = aws_vpc.pluto_vpc.id
  dynamic "ingress" {
    for_each = local.jenkins_ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = "tcp"
      cidr_blocks      = [var.cidr_ip]
      prefix_list_ids  = []
      ipv6_cidr_blocks = []
      security_groups  = []
      self             = false
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  tags = {
    Name = "jenkins_sg"
  }
}

resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.jenins_ami.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = aws_key_pair.deployer.key_name
  disable_api_termination = true
  subnet_id = aws_subnet.pluto_public_subnet_1a.id
  tags = {
    "Name" = "jenkins"
  }
}
