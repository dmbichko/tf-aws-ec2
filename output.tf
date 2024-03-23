# output.tf
output "ec2_public_ip" {
  description = "public ip for ec2"
  value       = aws_instance.public.public_ip
}
resource "local_sensitive_file" "private_key_output" {
  content = tls_private_key.tls-aws-key.private_key_pem
  filename          = "${path.module}/${var.key-name}.pem"
  file_permission = "0600"
}