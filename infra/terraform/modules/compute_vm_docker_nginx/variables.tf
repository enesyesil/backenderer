variable "name_prefix" {
  description = "Prefix for resource names (e.g., backenderer-dev)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the instance (e.g., Amazon Linux 2)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "Additional security group IDs to attach"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile" {
  description = "IAM instance profile name or ARN to attach"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}
