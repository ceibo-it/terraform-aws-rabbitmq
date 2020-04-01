module "label" {
  source     = "git::https://github.com/ceibo-it/terraform-null-label.git?ref=tags/0.0.1"
  namespace  = var.namespace
  name       = var.name
  stage      = var.stage
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

resource "random_string" "admin_password" {
  length  = 32
  special = false
}

resource "random_string" "rabbit_password" {
  length  = 32
  special = false
}

resource "random_string" "secret_cookie" {
  length  = 64
  special = false
}

resource "aws_iam_role" "role" {
  name               = local.cluster_name
  assume_role_policy = data.aws_iam_policy_document.policy_doc.json
}

resource "aws_iam_role_policy" "policy" {
  name = local.cluster_name
  role = aws_iam_role.role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF

}

resource "aws_iam_instance_profile" "profile" {
  name_prefix = local.cluster_name
  role        = aws_iam_role.role.name
}

resource "aws_security_group" "rabbitmq_elb" {
  name        = "rabbitmq_elb-${var.name}"
  vpc_id      = var.vpc_id
  description = "Security Group for the rabbitmq elb"

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rabbitmq ${var.name} ELB"
  }
}

resource "aws_launch_template" "mixed" {

  lifecycle {
    create_before_destroy = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.instance_volume_size
      volume_type = var.instance_volume_type
      iops        = var.instance_volume_iops
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.profile.arn
  }

  image_id      = data.aws_ami_ids.ami.ids[0]
  instance_type = var.ondemand_instance_type

  name                   = local.cluster_name
  vpc_security_group_ids = var.nodes_security_group_ids
  user_data              = data.template_file.cloud-init.rendered

  tags = {
    Name = local.cluster_name
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.cluster_name
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = local.cluster_name
    }
  }
}

resource "aws_autoscaling_group" "rabbitmq" {
  lifecycle {
    ignore_changes = [suspended_processes]
  }

  name                      = local.cluster_name
  min_size                  = var.min_size
  desired_capacity          = var.desired_size
  max_size                  = var.max_size
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  load_balancers            = [aws_elb.elb.name]
  vpc_zone_identifier       = var.ec2_subnet_ids

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.ondemand_base_capacity
      on_demand_percentage_above_base_capacity = var.ondemand_percentage_above_base_capacity
    }

    launch_template {
      launch_template_specification {
        launch_template_name = var.launch_template_name
        version              = "$Latest"
      }

      override {
        instance_type = var.ondemand_instance_type
      }

      override {
        instance_type = var.fallback_ondemand_instance_type
      }
    }
  }

  tag {
    key                 = "Name"
    value               = local.cluster_name
    propagate_at_launch = true
  }
}

resource "aws_elb" "elb" {
  name = "${local.cluster_name}"

  listener {
    instance_port     = 5672
    instance_protocol = "tcp"
    lb_port           = 5672
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 15672
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    interval            = 30
    unhealthy_threshold = 10
    healthy_threshold   = 2
    timeout             = 3
    target              = "TCP:5672"
  }

  subnets         = var.elb_subnet_ids
  idle_timeout    = 3600
  internal        = true
  security_groups = concat([aws_security_group.rabbitmq_elb.id], var.elb_additional_security_group_ids)

  tags = {
    Name = local.cluster_name
  }
}
