output "public_ips" {
  value = aws_instance.instance[*].public_ip
}

output "private_ips" {
  value = aws_instance.instance[*].private_ip
}

output "private_dns" {
  value = aws_instance.instance[*].private_dns
}

output "public_dns" {
  value = aws_instance.instance[*].public_dns
}

output "root_block_device_info" {
  value = aws_instance.instance[*].root_block_device
}