

module "network" {
  source = "../network"  
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"  
  map_public_ip_on_launch = true
}

variable "ami_id" {
  description = "The ID of the AMI to use for the instances"
  type        = string
  default     = "ami-02538f8925e3aa27a"
}


resource "aws_instance" "web" {
  count         = 3
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name = "terraform2" 
  subnet_id = aws_subnet.public_az1.id
  user_data     = file("metadata_script.sh") 
  tags = {
    Name = "web-${count.index}"
  }
}


output "instance_public_ips" {
  value = aws_instance.web.*.public_ip
}
