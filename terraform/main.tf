# 1. AWS varsayılan VPC ve Subnetleri
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 2. Ubuntu 22.04 LTS işletim sisteminin en güncel resmi imajını (AMI) buluyoruz
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical (Ubuntu'nun üreticisi)
}

# 3. GÜVENLİK: Sadece gerekli portları açan Security Group 
resource "aws_security_group" "insider_sg" {
  name        = "insider-devops-sg"
  description = "Allow SSH, HTTP, and Minikube NodePort traffic"
  vpc_id      = data.aws_vpc.default.id

  # SSH Portu (22): Sadece sunucuya bağlanmak için SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  # HTTP Portu (80): Uygulamamız internete buradan açılacak 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes NodePort Aralığı (30000-32767): dış dünya erişimi 
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Sunucunun internete çıkabilmesi için tüm çıkış (egress) trafiğine izin veriyoruz
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "insider-devops-sg"
  }
}

# 4. Sunucunun kendisine (EC2) bağlanabilmek için bir SSH Key Pair oluşturmamız lazım.
# Bunu AWS Console'dan manuel oluşturup ismini aşağıya yazacağız.

# 5. EC2 Sanal Sunucu Tanımı 
resource "aws_instance" "insider_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.insider_sg.id]
  key_name               = "insider-case-key"

  root_block_device {
    volume_size = 20 # Minikube ve Docker imajları için 20 GB disk alanı yeterli
    volume_type = "gp3"
  }

  tags = {
    Name = "insider-devops-server"
  }
}

# 6. Elastic IP (EIP) Tanımı: Sunucu her kapandığında IP'sinin değişmesini engeller 
resource "aws_eip" "insider_eip" {
  instance = aws_instance.insider_server.id
  domain   = "vpc"

  tags = {
    Name = "insider-devops-eip"
  }
}

# 7. Çıktı (Output): Terraform işini bitirince bize bağlanacağımız IP'yi terminale bassın
output "public_ip" {
  value       = aws_eip.insider_eip.public_ip
  description = "The Elastic IP address of the EC2 instance"
}