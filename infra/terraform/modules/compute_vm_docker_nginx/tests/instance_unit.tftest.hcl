mock_provider "aws" {}

override_data {
  target = data.aws_subnet.sel
  values = {
    id     = "subnet-12345678"
    vpc_id = "vpc-12345678"
  }
}

variables {
  name_prefix               = "backenderer-dev"
  ami_id                    = "ami-1234567890abcdef0"
  instance_type             = "t3.micro"
  subnet_id                 = "subnet-12345678"
  assign_public_ip          = true
  public_ingress_enabled    = true
  public_ingress_port       = 80
  security_group_ids        = []
  iam_instance_profile      = "backenderer-dev-instance-profile"
  env                       = "dev"
  register_script_content   = "#!/usr/bin/env bash\necho register"
  unregister_script_content = "#!/usr/bin/env bash\necho unregister"
}

run "instance_enforces_imdsv2" {
  command = plan

  assert {
    condition     = aws_instance.web.metadata_options[0].http_tokens == "required"
    error_message = "Expected the EC2 instance to require IMDSv2 tokens."
  }
}
