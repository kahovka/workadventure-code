provider "aws" {
profile = "itemis"
region = "eu-central-1"
}

variable "domain_name" {
  name = "yournamehere.io"
}
data "aws_ami" "ubuntu" {
  most_recent = true

    filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "adventure" {
ami = "ami-0eed77c38432886d2"
instance_type = "t3.small"
key_name = aws_key_pair.deployer.key_name
vpc_security_group_ids = [ aws_security_group.adventure.id ]
subnet_id = aws_subnet.adventure_subnet.id
associate_public_ip_address = true
root_block_device {
  volume_size = 20
}
}

resource "aws_key_pair" "deployer" {
key_name = "adventure_key"
public_key = file("./adventure.pub")
}

resource "aws_security_group" "adventure" {
name = "adventure_sg"
vpc_id = aws_vpc.adventure_vpc.id
}

resource "aws_security_group_rule" "adventure_in" {
type="ingress"
protocol = "TCP"
from_port = 0
to_port = 65535
security_group_id = aws_security_group.adventure.id
cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "adventure_out" {
type="egress"
protocol = "TCP"
from_port = 0
to_port = 65535
security_group_id = aws_security_group.adventure.id
cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_vpc" "adventure_vpc" {
cidr_block = "10.0.0.0/16"
enable_dns_hostnames = true
}

resource "aws_subnet" "adventure_subnet" {
cidr_block = "10.0.0.0/16"
availability_zone = "eu-central-1a"
vpc_id = aws_vpc.adventure_vpc.id
}

resource "aws_internet_gateway" "adventure" {
vpc_id = aws_vpc.adventure_vpc.id
}

resource "aws_route_table" "adventure_routes" {
vpc_id = aws_vpc.adventure_vpc.id
}

resource "aws_route_table_association" "adventure" {
subnet_id = aws_subnet.adventure_subnet.id
route_table_id = aws_route_table.adventure_routes.id
}

resource "aws_route" "adventure_internet" {
route_table_id = aws_route_table.adventure_routes.id
destination_cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.adventure.id
}

resource "aws_route53_delegation_set" "adventure_dns" {
reference_name = "advDNS"
lifecycle {
  prevent_destroy = true
  }
}

resource "aws_route53_zone" "adv_primary" {
name = vars.domain_name.name
delegation_set_id = aws_route53_delegation_set.adventure_dns.id
}

resource "aws_route53_record" "adv_dns_record" {
zone_id = aws_route53_zone.adv_primary.zone_id
name = vars.domain_name.name
type = "A"
ttl = "300"
records = [aws_instance.adventure.public_ip]
}

resource "aws_route53_record" "adv_api_dns_record" {
zone_id = aws_route53_zone.adv_primary.zone_id
name = vars.domain_name.name
type = "A"
ttl = "300"
records = [aws_instance.adventure.public_ip]
}
