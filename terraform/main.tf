terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
    backend "s3" {
        bucket = "s3terraformtaskstorage"
        region = "us-east-1"
        key    = "storage/statefile"
    }
}

module "networking_module" {
    source = "./modules/network"
    cidr_block_vpc = "10.0.0.0/16"
    cidr_block_subnet1a = "10.0.2.0/24"
    cidr_block_subnet1b = "10.0.3.0/24"
    cidr_block_subnet2 = "10.0.4.0/24"
    cidr_block_route = "0.0.0.0/0"
    cidr_block_ipv6 = "::/0"
    availability_zone1 = "us-east-1a"
    availability_zone2 = "us-east-1b"
    map_public_ip_on_launch = true
    port_http = "80"
    port_https = "443"
    port_egres = "0"
    protocol = "tcp"
    protocol_egres = "-1"
    vpc_name = "my_vpc"
    eip_name = "my_eip_for_nat"
    nat_name = "NAT for private subnet"
    sg_name = "my_sg"
    eip_name_2 = "lsvar.eip_name"
    sg_name_ec2 = "my_sc_ec2"
}


module "ec2_asg_lb_module" {
    source = "./modules/ec2_asg_lb"
    load_balancer_type = "application"
    internal = "false"
    port = "80"
    protocol = "HTTP"
    lb_name = "my-lb-tg"
    lb_type = "forward"
    ami = "ami-02538f8925e3aa27a"
    ec2_name = "my_instance"
    instance_type = "t2.micro"
    associate_public_ip_address = "false"
    name_prefix = "ec2_launch"
    user_data = filebase64("metadata_script.sh")
    resource_type = "instance"
    desired_capacity = "3"
    max_size = "3"
    min_size = "3"
    vrsion = "$Latest"
    security_group_id = module.networking_module.aws_sg_id
    subnet_one_id = module.networking_module.subnet_id1
    subnet_two_id = module.networking_module.subnet_id2
    internetgateway = module.networking_module.igw_id
    awsvpc_id = module.networking_module.vpc_id
    subnet_priv_id = module.networking_module.subnet_id_priv
    sec_group_ec2_id = module.networking_module.aws_sg_id_ec2

}
