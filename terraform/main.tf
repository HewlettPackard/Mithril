# 1. Create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

# 3. Create Custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# 4. Create a Subnet 
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod-subnet"
  }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create Security Group to allow ports
resource "aws_security_group" "allow_web" {
  name        = "mithril_sg_test"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTP"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
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

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "mithril-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.mithril-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

# 9. Create Ubuntu server
resource "aws_instance" "mithril_instance" {
  ami               = var.EC2_AMI
  instance_type     = var.EC2_INSTANCE_TYPE
  availability_zone = "us-east-1a"
  key_name          = var.EC2_KEY_PAIR

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.mithril-nic.id
  }

  root_block_device {
    volume_size = var.VOLUME_SIZE
  }

  tags = {
    Name = "mithril-testing"
  }
  user_data = data.template_file.init.rendered
}

data "aws_secretsmanager_secret" "secrets" {
  name = "mithril-jenkins-integration-tests"
}

data "aws_secretsmanager_secret_version" "mithril_secret" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}

data "template_file" "init" {
  template = file("user_data_bootstrap.sh")

  vars = {
    access_key        = jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.mithril_secret.secret_string))["ACCESS_KEY_ID"],
    secret_access_key = jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.mithril_secret.secret_string))["SECRET_ACCESS_KEY"],
    region            = var.ECR_REGION,
    tag               = var.TAG,
    hub               = var.HUB,
    build_tag         = var.BUILD_TAG
  }
}