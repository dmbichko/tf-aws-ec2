resource "tls_private_key" "tls-aws-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a private key for aws instances
resource "aws_key_pair" "instance_key" {
  key_name   = var.key-name
  public_key = tls_private_key.tls-aws-key.public_key_openssh
}