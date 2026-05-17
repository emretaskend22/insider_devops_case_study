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
  type        = string
  description = "The name of the AWS SSH key pair to access the EC2 instance"
}