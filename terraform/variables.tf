variable "aws_region" {
  type    = string
  default = "eu-central-1" # Frankfurt 
}

variable "instance_type" {
  type    = string
  default = "t3.small" 
}

variable "my_ip" {
  type        = string
  description = "My local public IP address for secure access"
}

variable "key_name" {
  description = "Name of the SSH key pair in AWS"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository path for OIDC (e.g., username/repo-name)"
  type        = string
  default     = "emretaskend22/insider_devops_case_study" 
}