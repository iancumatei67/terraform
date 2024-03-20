#VPC


resource "aws_vpc" "main" {
  cidr_block = var.cidr_block_vpc
  tags = {
    name = var.vpc_name
  }
}

resource "aws_subnet" "my_subnet_1a"{
  vpc_id = aws_vpc.main.id
  cidr_block = var.cidr_block_subnet1a
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone = var.availability_zone1
}

resource "aws_subnet" "my_subnet_1b"{
  vpc_id = aws_vpc.main.id
  cidr_block = var.cidr_block_subnet1b
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone = var.availability_zone2
}

resource "aws_subnet" "my_subnet_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.cidr_block_subnet2
    map_public_ip_on_launch = var.map_public_ip_on_launch
    availability_zone = var.availability_zone2
}

#INTERNET GATEWAY

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

#ROUTE TABLES 

resource aws_route_table "my_rt" {
  vpc_id = aws_vpc.main.id

  route{
    cidr_block = var.cidr_block_route
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
    Name = var.eip_name_2
  }
}

resource "aws_nat_gateway" "nat_for_private_subnet" {
  allocation_id = aws_eip.my_eip.id
  subnet_id = aws_subnet.my_subnet_1a.id
  tags = {
    Name = var.nat_name
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "my_rt_private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.cidr_block_route
    nat_gateway_id = aws_nat_gateway.nat_for_private_subnet.id
  }
}

resource "aws_route_table_association" "my_rta3" {
  subnet_id = aws_subnet.my_subnet_2.id
  route_table_id = aws_route_table.my_rt_private.id
}

 # FIREWALL 

resource "aws_security_group" "my_sg" {
  name = var.sg_name
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow http request from anywhere"
    protocol = var.protocol
    from_port = var.port_http
    to_port = var.port_http
    cidr_blocks = [var.cidr_block_route]
    ipv6_cidr_blocks = [var.cidr_block_ipv6]
  }
  ingress {
    description = "Allow https request from anywhere"
    protocol = var.protocol
    from_port = var.port_https
    to_port = var.port_https
    cidr_blocks = [var.cidr_block_route]
    ipv6_cidr_blocks = [var.cidr_block_ipv6]
  }
  egress {
    from_port = var.port_egres
    to_port = var.port_egres
    protocol = var.protocol_egres
    cidr_blocks = [var.cidr_block_route]
  }
}

resource "aws_security_group" "my_sg_for_ec2" {
  name = var.sg_name_ec2
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow http request from Load Balancer"
    protocol = var.protocol
    from_port = var.port_http
    to_port = var.port_http
    security_groups = [aws_security_group.my_sg.id]
  }

  egress {
    from_port = var.port_egres
    to_port = var.port_egres
    protocol = var.protocol_egres
    cidr_blocks = [var.cidr_block_route]
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow traffic from your IP address"
    protocol    = var.protocol
    from_port   = var.port_http
    to_port     = var.port_http
    cidr_blocks = ["85.204.75.2/32"]
    ipv6_cidr_blocks = [var.cidr_block_ipv6]  
  }

  egress {
    from_port = var.port_egres
    to_port = var.port_egres
    protocol = var.protocol_egres
    cidr_blocks = [var.cidr_block_route]
  }
}
