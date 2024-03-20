output "vpc_id" {
    value = aws_vpc.main.id
}

output "igw_id" {
    value = aws_internet_gateway.igw.id
}

output "subnet_id1" {
    value = aws_subnet.my_subnet_1a.id
}

output "subnet_id2" {
    value = aws_subnet.my_subnet_1b.id
}

output "subnet_id_priv" {
    value = aws_subnet.my_subnet_2.id
}

output "route_table_id1" {
    value = aws_route_table.my_rt.id
}

output "route_table_id_priv" {
    value = aws_route_table.my_rt_private.id
}

output "aws_sg_id" {
    value = aws_security_group.my_sg.id
}

output "allocation_id" {
    value = aws_eip.my_eip.id
}

output "aws_sg_id_ec2" {
    value = aws_security_group.my_sg_for_ec2.id
}

output "lb_sg_id" {
    value = aws_security_group.lb_sg.id
}