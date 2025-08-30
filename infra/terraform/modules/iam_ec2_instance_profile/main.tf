locals {
  role_name   = "${var.name_prefix}-ec2-role"
  prof_name   = "${var.name_prefix}-ec2-instance-profile"
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = var.tags
}

# Attach managed policies:
# - SSM core (so SSM Run Command works)
# - ECR ReadOnly (so docker pulls from ECR work if you use ECR)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2" {
  name = local.prof_name
  role = aws_iam_role.ec2.name
  tags = var.tags
}
