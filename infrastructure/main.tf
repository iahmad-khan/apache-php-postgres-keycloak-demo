# Define the provider (AWS)

provider "aws" {
  region = "eu-west-3"
}

# IAM policy for Certbot to manage Route 53 DNS records
resource "aws_iam_policy" "certbot_route53_policy" {
  name        = "certbot-route53-policy"
  description = "IAM policy for Certbot to manage Route 53 DNS records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "route53:ChangeResourceRecordSets"
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      # Add additional permissions as needed
    ]
  })
}

# IAM role for the EC2 instance running Certbot
resource "aws_iam_role" "certbot_role" {
  name = "certbot-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
# IAM instance profile for the EC2 instance
resource "aws_iam_instance_profile" "certbot_profile" {
  name = "certbot-profile"
  role = aws_iam_role.certbot_role.name
}

# Attach the Certbot IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "certbot_policy_attachment" {
  role       = aws_iam_role.certbot_role.name
  policy_arn = aws_iam_policy.certbot_route53_policy.arn
}


# Create a key pair for SSH access
resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key"
  public_key = file("~/.ssh/id_rsa.pub") # Update with your public key path
}

resource "aws_vpc" "demo" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "demo"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.demo.id
}

# Create a subnet in the VPC
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "172.16.1.0/24" # Change if needed
  map_public_ip_on_launch = true
}

# Create a route table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}


# Create security groups
resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.demo.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Security group for application server"
  vpc_id      = aws_vpc.demo.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch instances
resource "aws_instance" "bastion_host" {
  ami           = "ami-0ebd2bf0042bb3e85" # Amazon Linux AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet.id
  key_name      = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  user_data     = <<-EOF
                              #!/bin/bash  
                              sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
                              sudo systemctl restart sshd
                            EOF

  tags = {
    Name = "bastion-host"
  }
}

resource "aws_instance" "app_server" {
  ami                  = "ami-0ebd2bf0042bb3e85" # Amazon Linux AMI ID
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.subnet.id
  key_name             = aws_key_pair.ssh_key.key_name
  iam_instance_profile = aws_iam_instance_profile.certbot_profile.name # Attach IAM role to the instance
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true
  user_data            = <<-EOF
                              #!/bin/bash
                              sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
                              sudo systemctl restart sshd
                              sudo yum update -y
                              sudo yum install -y docker
                              sudo yum install -y docker-compose-plugin
                              sudo systemctl enable docker
                              sudo systemctl start docker
                              sudo yum install -y certbot python3-certbot-dns-route53
                              #sleep 100
                              # Run Certbot to obtain SSL certificates
                              #certbot certonly --dns-route53 -d ijazxampledemo.fun -d app.ijazxampledemo.fun --non-interactive --agree-tos --email test@ijazxampledemo.fun
                              #certbot certonly --dns-route53 -d ijazxampledemo.fun -d keycloak.ijazxampledemo.fun --non-interactive --agree-tos --email test@ijazxampledemo.fun
                            EOF
  tags = {
    Name = "app-server"
  }
}


# Output the public IPs of instances
output "bastion_host_ip" {
  value = aws_instance.bastion_host.public_ip
}

output "app_server_ip" {
  value = aws_instance.app_server.public_ip
}



resource "aws_route53_zone" "xampledemo_zone" {
  name = "ijazxampledemo.fun"
}

resource "aws_route53_record" "keycloak_record" {
  zone_id = aws_route53_zone.xampledemo_zone.zone_id
  name    = "keycloak.ijazxampledemo.fun"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.app_server.public_ip}"]
}

resource "aws_route53_record" "app_record" {
  zone_id = aws_route53_zone.xampledemo_zone.zone_id
  name    = "app.ijazxampledemo.fun"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.app_server.public_ip}"]
}

