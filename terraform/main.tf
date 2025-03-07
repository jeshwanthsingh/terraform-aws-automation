provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "jenkins_server" {
  ami           = "ami-00874d747dde814fa"  # Ubuntu AMI for us-east-1, change if needed
  instance_type = "t2.medium"
  key_name      = "Terraform_Automation"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  tags = {
    Name = "Jenkins-Server"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y openjdk-11-jdk
    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
    echo "deb http://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
    sudo apt update -y
    sudo apt install -y jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    sudo apt install -y docker.io
    sudo usermod -aG docker jenkins
    sudo usermod -aG docker ubuntu
    sudo systemctl restart jenkins
  EOF
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and Jenkins traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins Web UI"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "jenkins-sg"
  }
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins_server.public_ip
  description = "Public IP of Jenkins Server"
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins_server.public_ip}:8080"
  description = "URL for Jenkins Web UI"
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/Terraform_Automation.pem ubuntu@${aws_instance.jenkins_server.public_ip}"
  description = "SSH command to connect to the instance"
}
