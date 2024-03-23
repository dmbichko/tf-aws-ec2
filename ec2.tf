# Private ec2
resource "aws_instance" "private" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  availability_zone      = "${data.aws_region.current.name}a"
  vpc_security_group_ids = [aws_security_group.ssh.id, ]
  key_name               = aws_key_pair.instance_key.key_name
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-private-ec2" })
  )
}

# Public ec2
resource "aws_instance" "public" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh.id, ]
  key_name               = aws_key_pair.instance_key.key_name
  availability_zone      = "${data.aws_region.current.name}a"
  
  user_data              = <<-EOF
      #!/bin/bash
      yum update -y
      yum install httpd unzip -y
      systemctl start httpd
      systemctl enable httpd
      cd /var/www/html
      # Fetch instance metadata using the token
      TOKEN=$(curl -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 300" -H "X-aws-ec2-metadata-token: true" "http://169.254.169.254/latest/api/token")
      PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
      INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
      INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type)
      AVAILABILITY_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
      PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

      # Create index.html
      echo "<!DOCTYPE html>
      <html>
      <head>
        <title>EC2 Metadata Example</title>
        <style>
          body {
            font-family: Arial, sans-serif;
          }

          h1 {
            color: #333;
          }

          h2 {
            color: #666;
            margin-top: 20px;
          }

          .red {
            color: red;
          }

          .green {
            color: green;
          }
        </style>
      </head>
      <body>
        <h1>EC2 Metadata</h1>

        <h2>Public IP:</h2>
        <pre class=\"red\">$PUBLIC_IP</pre>

        <h2>Instance ID:</h2>
        <pre class=\"green\">$INSTANCE_ID</pre>

        <h2>Instance Type:</h2>
        <pre class=\"green\">$INSTANCE_TYPE</pre>
        
        <h2>Availability Zone:</h2>
        <pre class=\"green\">$AVAILABILITY_ZONE</pre>

        <h2>Private IP:</h2>
        <pre class=\"green\">$PRIVATE_IP</pre>
      </body>
      </html>" > index.html
    EOF
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-public-ec2" })
  )
}