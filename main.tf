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