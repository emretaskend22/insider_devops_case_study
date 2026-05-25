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


# 5. EC2 Sanal Sunucu Tanımı 
resource "aws_instance" "insider_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.insider_sg.id]
  key_name               = var.key_name
  source_dest_check      = false
  
  # Makine açılır açılmaz scripti otomatik çalıştırır.
  user_data = file("${path.module}/scripts/install_dependencies.sh")

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

# OIDC Sağlayıcısı (Identity Provider) Tanımı 
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# GitHub Actions'ın AWS üzerinde üstleneceği (Assume) IAM Rolü
resource "aws_iam_role" "github_actions_oidc_role" {
  name        = "github-actions-oidc-role"
  description = "Role used by GitHub Actions CI/CD pipeline for Insider Case Study"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "github-actions-oidc-role"
  }
}

# Pipeline'ın saniyelik olarak kapıyı açıp (Authorize) kapatabilmesi (Revoke) için kısıtlı Politika
resource "aws_iam_policy" "github_actions_security_group_policy" {
  name        = "github-actions-sg-management-policy"
  description = "Allows GitHub Actions to dynamically whitelist its IP on the insider security group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "${aws_security_group.insider_sg.arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Politikayı (Policy) IAM Rolüne bağlıyoruz
resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_actions_oidc_role.name
  policy_arn = aws_iam_policy.github_actions_security_group_policy.arn
}

# Çıktı (Output): Rolün ARN adresini GitHub Secrets'a (AWS_ROLE_ARN) eklemek için terminale bassın
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_oidc_role.arn
  description = "The ARN of the IAM role for GitHub Actions OIDC authentication"
}