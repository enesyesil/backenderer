
data "aws_subnet" "sel" { id = var.subnet_id }

resource "aws_security_group" "vm_sg" {
  name        = "${var.name_prefix}-sg"
  description = "Backenderer security group"
  vpc_id      = data.aws_subnet.sel.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  user_data = templatefile("${path.module}/user_data.tpl", {
    register_script_content   = var.register_script_content
    unregister_script_content = var.unregister_script_content
  })

  tags = { Name = "${var.name_prefix}-vm", Backenderer = var.env }
}
