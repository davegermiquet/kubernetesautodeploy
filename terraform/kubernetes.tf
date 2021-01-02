terraform {

  backend "s3" {
    bucket = "terraforms3state"
    key    = "autodeploy"
    region = "us-east-1"
}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}


resource "aws_iam_role" "kubernetes_role" {
  name = "kubernetes"

  assume_role_policy = <<END
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
END

 tags = {
    Name        = "kubernetes_deploy"
   }
}


resource "aws_iam_policy" "kubernetes_policy" {
  name        = "kubernetes_policy"
  description = "Policies for deploying kubernetes"
  policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "kubernetes_role_policy" {
  role       = aws_iam_role.kubernetes_role.name
  policy_arn = aws_iam_policy.kubernetes_policy.arn
}



resource "aws_iam_instance_profile" "kubernetes_iam_aws_instance" {
  name  = "kubernetes_iam_aws_instance"
  role = aws_iam_role.kubernetes_role.name
}


variable "SSH_PUB" {
  type        = string
  description = "SSH KEY FOR AMAZON HOSTS"
}

resource "aws_vpc" "kubernetes_vpc" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name        = "kubernetes_deploy"
  }
}

resource "aws_route53_zone" "kubernetes_private_route_zone" {
   name = "kubernetes_private_route_zone"

  vpc {
        vpc_id = aws_vpc.kubernetes_vpc.id
  }
}

resource "aws_route53_record" "kubernetes_private_route53_route" {
  zone_id = aws_route53_zone.kubernetes_private_route_zone.zone_id
  name    = "trulycanadian.net"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.kubernetes_private_route_zone.name_servers
}

resource "aws_subnet" "kubernetes_public_subnet" {
  vpc_id     = aws_vpc.kubernetes_vpc.id
  cidr_block = "192.168.10.0/24"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.kubernetes_gw]
  tags = {
    Name        = "kubernetes_deploy"
  }
}
resource "aws_subnet" "kubernetes_private_subnet" {
  vpc_id     = aws_vpc.kubernetes_vpc.id
  cidr_block = "192.168.9.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name        = "kubernetes_deploy"
 }
}

resource "aws_internet_gateway" "kubernetes_gw" {
  depends_on        = [aws_vpc.kubernetes_vpc]
  vpc_id =aws_vpc.kubernetes_vpc.id
}





resource "aws_route_table" "kubernetes_public_route_table" {
depends_on        = [aws_subnet.kubernetes_public_subnet]
  vpc_id = aws_vpc.kubernetes_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubernetes_gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.kubernetes_egress_gw.id
  }

   tags = {
    Name        = "kubernetes_deploy"
   }
}

resource "aws_route_table_association" "kubernetes_private_subnet_route_association" {
    subnet_id = aws_subnet.kubernetes_private_subnet.id
    route_table_id = aws_route_table.kubernetes_public_route_table.id
}


resource "aws_route_table_association" "kubernetes_public_subnet_route_association" {
    depends_on        = [aws_route_table.kubernetes_public_route_table]
     subnet_id      = aws_subnet.kubernetes_public_subnet.id
     route_table_id = aws_route_table.kubernetes_public_route_table.id
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.SSH_PUB
}

resource "aws_security_group" "kubernetes_default_sg" {
  name = "kubernetes_default_sg"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"
  vpc_id = aws_vpc.kubernetes_vpc.id

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    self        = true
  }
}



resource "aws_egress_only_internet_gateway" "kubernetes_egress_gw" {
  vpc_id = aws_vpc.kubernetes_vpc.id
  tags = {
    Name        = "kubernetes_deploy"
  }
}


resource "aws_security_group" "allow_kubernetes_master" {
    name        = "allow_kubernetes_master"
    description = "allow kubernetes port"
    vpc_id      = aws_vpc.kubernetes_vpc.id

    ingress {
        description = "needed for kubernetes master"
        from_port   = 6443
        to_port     = 6443
        protocol    = "tcp"
        cidr_blocks = ["192.168.0.0/16"]
    }

    ingress {
          description = "needed for kubernetes master "
          from_port   = 2379
          to_port     = 2380
          protocol    = "tcp"
         cidr_blocks = ["192.168.0.0/16"]
    }


    ingress {
        description = "needed for kubernetes master"
        from_port   = 10250
        to_port     = 10252
        protocol    = "tcp"
        cidr_blocks = ["192.168.0.0/16"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
    Name = "kubernetes"
    }
    depends_on        = [ aws_vpc.kubernetes_vpc]
    }

resource "aws_security_group" "allow_kubernetes_slave" {
   name        = "allow_kubernetes_slave"
   description = "allow kubernetes port"
   vpc_id      = aws_vpc.kubernetes_vpc.id

    ingress {
        description = "needed for kubernetes slave"
        from_port   = 30000
        to_port     = 32767
        protocol    = "tcp"
        cidr_blocks = ["192.168.0.0/16"]
    }

    ingress {
        description = "needed for kubernetes slave "
        from_port   = 2379
        to_port     = 2380
        protocol    = "tcp"
        cidr_blocks = ["192.168.0.0/16"]
   }
   ingress {
        description = "needed for kubernetes slave"
        from_port   = 10250
        to_port     = 10252
        protocol    = "tcp"
        cidr_blocks = ["192.168.0.0/16"]
    }
tags = {
Name = "kubernetes"
}
depends_on        = [ aws_vpc.kubernetes_vpc]
}
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Open SSH port"
  vpc_id      = aws_vpc.kubernetes_vpc.id

  ingress {
    description = "SSH from VPC"
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
    Name = "ssh"
  }
depends_on        = [ aws_vpc.kubernetes_vpc]
}

resource "aws_security_group" "allow_squid" {
  name        = "allow_squid"
  description = "Open squid port"
  vpc_id      = aws_vpc.kubernetes_vpc.id

  ingress {
  description = "SSH from VPC"
  from_port   = 3128
  to_port     = 3128
  protocol    = "tcp"
  cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
Name = "squid"
}
depends_on        = [ aws_vpc.kubernetes_vpc]
}

resource "aws_instance" "kuber_master_ec2_instance" {
  ami           = "ami-0885b1f6bd170450c"
  instance_type = "t2.medium"
  iam_instance_profile = aws_iam_instance_profile.kubernetes_iam_aws_instance.name,
  subnet_id = aws_subnet.kubernetes_public_subnet.id
vpc_security_group_ids = [aws_security_group.allow_ssh.id,aws_security_group.kubernetes_default_sg.id,aws_security_group.allow_kubernetes_master.id,aws_security_group.allow_squid.id],
  key_name = aws_key_pair.deployer.key_name
  root_block_device {
      volume_size = 16
  }
  tags = {
    Name        = "kubernetes_deploy"
  }
}

resource "aws_instance" "kuber_node_ec2_instance" {
  ami           = "ami-0885b1f6bd170450c"
  instance_type = "t2.medium"
  subnet_id = aws_subnet.kubernetes_private_subnet.id
  iam_instance_profile = aws_iam_instance_profile.kubernetes_iam_aws_instance.name
vpc_security_group_ids = [aws_security_group.allow_ssh.id,aws_security_group.kubernetes_default_sg.id,aws_security_group.allow_kubernetes_slave.id,aws_security_group.allow_squid.id]
  key_name = aws_key_pair.deployer.key_name
  source_dest_check = false
  root_block_device {
      volume_size = 16
  }

  tags = {
    Name        = "kubernetes_deploy"
  }
}


output "kuber_node_aws_instance_private_ip" {
   value = aws_instance.kuber_node_ec2_instance.private_ip
}



output "kuber_master_aws_instance_private_ip" {
    value = aws_instance.kuber_master_ec2_instance.private_ip
}


output "kuber_master_aws_instance_public_ip" {
    value = aws_instance.kuber_master_ec2_instance.public_ip
}