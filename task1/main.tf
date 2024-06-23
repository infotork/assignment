provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "allow_tomcat" {
  name_prefix = "allow_tomcat"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tomcat access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tomcat"
  }
}

resource "aws_instance" "tomcat" {
  count         = 2 
  ami           = "ami-0e0bf53f6def86294"  # Linux 2023
  instance_type = "t2.micro"
  key_name      = "connect-ansible"  # Replace with your key name
  vpc_security_group_ids = [aws_security_group.allow_tomcat.id]
user_data = <<-EOF
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo yum update -y
sudo yum install -y wget
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo yum install -y java-1.8.0-amazon-corretto-devel
wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.35/bin/apache-tomcat-8.5.35.tar.gz
sudo tar xzf apache-tomcat-8.5.35.tar.gz -C /opt/
sudo mv /opt/apache-tomcat-8.5.35 /opt/tomcat
sudo chown -R ec2-user:ec2-user /opt/tomcat
sudo chmod +x /opt/tomcat/bin/*.sh
sudo sed -i 's/port="8080"/port="8080" address="0.0.0.0"/' /opt/tomcat/conf/server.xml
sudo /opt/tomcat/bin/startup.sh
EOF  
	

tags = {
    Name = "TomcatServer"
  }
}

output "hostname_and_port" {
  value = [
    for instance in aws_instance.tomcat :
     "${instance.public_dns}:8080" 
  ]
}
