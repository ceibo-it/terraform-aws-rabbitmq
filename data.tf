data "aws_ami_ids" "ami" {
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-2018*-gp2"]
  }
}

data "aws_iam_policy_document" "policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "template_file" "cloud-init" {
  template = file("${path.module}/cloud-init.yaml")

  vars = {
    sync_node_count = var.desired_size
    asg_name        = local.cluster_name
    region          = var.region
    admin_password  = random_string.admin_password.result
    rabbit_password = random_string.rabbit_password.result
    secret_cookie   = random_string.secret_cookie.result
    message_timeout = 3 * 24 * 60 * 60 * 1000 # 3 days
  }
}
