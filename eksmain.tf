provider "aws" {
  region = "ap-south-1"
}


resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins_instance_profile"
  role = "terraform"  
}


resource "aws_instance" "jenkins_instance" {
  ami           = "ami-0522ab6e1ddcc7055" 
  instance_type = "t2.medium"
  key_name      = "new"  # Use your existing key pair

  # Attach the IAM instance profile
  iam_instance_profile = aws_iam_instance_profile.jenkins_instance_profile.name

  tags = {
    Name = "JenkinsServer"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update 
              sudo apt install -y git maven wget unzip
              sudo apt install docker.io -y
              sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
              echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update
              sudo apt-get install jenkins -y 
              sudo systemctl start jenkins
              sudo systemctl enable jenkins
              sudo service docker start
              sudo usermod -aG docker jenkins
              sudo service docker restart
              sudo service jenkins restart
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install
              curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.6/2024-07-12/bin/linux/amd64/kubectl
              chmod +x ./kubectl
              mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
              # for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
              ARCH=amd64
              PLATFORM=$(uname -s)_$ARCH
              curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
              # (Optional) Verify checksum
              curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
              tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
              sudo mv /tmp/eksctl /usr/local/bin
              eksctl create cluster --name selva-cluster --region ap-south-1 --node-type t2.small
              sudo mkdir -p /var/lib/jenkins/.kube/
              sudo mv /home/ubuntu/.kube/config /var/lib/jenkins/.kube/config
              sudo chown -R jenkins:jenkins /home/ubuntu/.kube
              sudo chmod -R 700 /home/ubuntu/.kube
              sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube/config
              sudo chmod -R 700 /var/lib/jenkins/.kube/config
              export KUBECONFIG=/var/lib/jenkins/.kube/config
              sudo service jenkins restart
              EOF

  vpc_security_group_ids = ["sg-0519c88d491c653de"]  
}

output "jenkins_url" {
  value = aws_instance.jenkins_instance.public_ip
}
