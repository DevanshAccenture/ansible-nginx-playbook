provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "az_a" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "ap-south-1a"
  default_for_az    = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "p15" {
  name        = "p15-ansible-target-sg"
  description = "SSH from lab VM, HTTP open"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["20.197.25.80/32"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "target" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.az_a.id
  vpc_security_group_ids      = [aws_security_group.p15.id]
  key_name                    = "capstone-win-key"
  associate_public_ip_address = true
  user_data = file("userdata.sh")
  user_data_replace_on_change = true
  tags = { Name = "p15-ansible-target" }
}

output "public_ip" {
  value = aws_instance.target.public_ip
}
