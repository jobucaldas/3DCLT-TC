output "vpc_id" {
  value = aws_vpc.main.id
}

output "data_security_group_id" {
  value = aws_security_group.data.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_public_ips" {
  value = aws_eip.nat[*].public_ip
}
