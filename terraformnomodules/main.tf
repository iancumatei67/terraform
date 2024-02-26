terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "my-vpc"
  }
}

resource "aws_subnet" "my_subnet_1a"{
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "my_subnet_1b"{
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "my_subnet_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.4.0/24"
    map_public_ip_on_launch = false
    availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource aws_route_table "my_rt" {
  vpc_id = aws_vpc.main.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "my_rta1" {
  subnet_id = aws_subnet.my_subnet_1a.id
  route_table_id = aws_route_table.my_rt.id
}

resource "aws_route_table_association" "my_rta2" {
  subnet_id = aws_subnet.my_subnet_1b.id
  route_table_id = aws_route_table.my_rt.id
}

# NAT

resource "aws_eip" "my_eip" {
  depends_on = [aws_internet_gateway.igw]
  domain = "vpc"
  tags = {
    Name = "my_eip_for_nat"
  }
}

resource "aws_nat_gateway" "nat_for_private_subnet" {
  allocation_id = aws_eip.my_eip.id
  subnet_id = aws_subnet.my_subnet_1a.id
  tags = {
    Name = "NAT for priate subnet"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "my_rt_private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_for_private_subnet.id
  }
}

resource "aws_route_table_association" "my_rta3" {
  subnet_id = aws_subnet.my_subnet_2.id
  route_table_id = aws_route_table.my_rt_private.id
}

resource "aws_lb" "my_lb" {
  name = "my-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.my_sg.id]
  subnets = [aws_subnet.my_subnet_1a.id, aws_subnet.my_subnet_1b.id]
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_lb_target_group" "my_lb_tg" {
  name = "my-lb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.my_lb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.my_lb_tg.arn
  }
}

resource "aws_security_group" "my_sg" {
  name = "my_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow http request from anywhere"
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description = "Allow https request from anywhere"
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "my_sg_for_ec2" {
  name = "my_sg_for_ec2"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow http request from Load Balancer"
    protocol = "tcp"
    from_port = 80 # 
    to_port = 80 # 
    security_groups = [aws_security_group.my_sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_launch_template" "web" {
  name_prefix = "ec2_launch"
  image_id = "ami-02538f8925e3aa27a"
  instance_type = "t2.micro"
  user_data     = filebase64("metadata_script.sh") 

  network_interfaces {
    associate_public_ip_address = false
    subnet_id = aws_subnet.my_subnet_2.id
    security_groups = [aws_security_group.my_sg_for_ec2.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "my_instance"
    }
  }
}

resource "aws_autoscaling_group" "my_asg" {
  desired_capacity = 3
  max_size = 3
  min_size = 3

  target_group_arns = [aws_lb_target_group.my_lb_tg.arn]
  vpc_zone_identifier = [aws_subnet.my_subnet_2.id]

  launch_template {
    id = aws_launch_template.web.id
    version = "$Latest"
  }
}
