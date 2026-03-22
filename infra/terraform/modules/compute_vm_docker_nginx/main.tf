data "aws_subnet" "sel" { id = var.subnet_id }

resource "aws_security_group" "vm_sg" {
  name        = "${var.name_prefix}-sg"
  description = "Backenderer security group"
  vpc_id      = data.aws_subnet.sel.vpc_id

  dynamic "ingress" {
    for_each = var.public_ingress_enabled ? [var.public_ingress_port] : []

    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
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
  associate_public_ip_address = var.assign_public_ip

  metadata_options {
    http_tokens = "required"
  }

  user_data = templatefile("${path.module}/user_data.tpl", {
    register_script_content   = var.register_script_content
    unregister_script_content = var.unregister_script_content
  })

  tags = { Name = "${var.name_prefix}-vm", Backenderer = var.env }
}
