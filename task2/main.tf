provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "allow_ansible" {
  name_prefix = "allow_ansible"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ansible"
  }
}

resource "aws_instance" "ansible_change_name" {
  count         = 6 
  ami           = "ami-0e0bf53f6def86294"  # Linux 2023
  instance_type = "t2.micro"
  key_name      = "connect-ansible"  # Replace with your key name
  vpc_security_group_ids = [aws_security_group.allow_ansible.id]
	

tags = {
    Name = "Ansible-change-hostname"
  }
}

output "hostname_and_port" {
  value = [
    for instance in aws_instance.ansible_change_name :
     "${instance.public_dns}:${instance.public_ip}" 
  ]
}
