variable "name_prefix" { type = string }
variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "subnet_id" { type = string }
variable "security_group_ids" { type = list(string) }
variable "iam_instance_profile" { type = string }
variable "env" { type = string }

resource "aws_security_group" "vm_sg" {
  name        = "${var.name_prefix}-sg"
  description = "Backenderer security group"

  # Allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # No SSH!

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = concat([aws_security_group.vm_sg.id], var.security_group_ids)
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = true
  key_name                    = null

  user_data = templatefile("${path.module}/user_data.tpl", {
    name_prefix = var.name_prefix
  })

  tags = {
    Name        = "${var.name_prefix}-vm"
    Backenderer = var.env
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "instance_id" {
  value = aws_instance.web.id
}
