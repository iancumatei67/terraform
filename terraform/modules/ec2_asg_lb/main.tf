# LOAD BALANCER 

resource "aws_lb" "my_lb" {
  name = var.lb_name
  internal = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups = [var.security_group_id]
  subnets = [var.subnet_one_id, var.subnet_two_id]
  depends_on = [var.internetgateway]
}

resource "aws_lb_target_group" "my_lb_tg" {
  name = var.lb_name
  port = var.port
  protocol = var.protocol
  vpc_id = var.awsvpc_id
}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.my_lb.arn
  port = var.port
  protocol = var.protocol
  default_action {
    type = var.lb_type
    target_group_arn = aws_lb_target_group.my_lb_tg.arn
  }
}


# EC2 INSTANCE AND AUTOSCALING 

resource "aws_launch_template" "web" {
  name_prefix = var.name_prefix
  image_id = var.ami
  instance_type = var.instance_type
  user_data     = var.user_data

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    subnet_id = var.subnet_priv_id
    security_groups = [var.sec_group_ec2_id]
  }

  tag_specifications {
    resource_type = var.resource_type
    tags = {
      Name = var.ec2_name
    }
  }
}

resource "aws_autoscaling_group" "my_asg" {
  desired_capacity = var.desired_capacity
  max_size = var.max_size
  min_size = var.min_size

  target_group_arns = [aws_lb_target_group.my_lb_tg.arn]
  vpc_zone_identifier = [var.subnet_priv_id]

  launch_template {
    id = aws_launch_template.web.id
    version = var.vrsion
  }
}

