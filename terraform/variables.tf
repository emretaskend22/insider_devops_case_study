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