variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Default region for aws provider"
}

variable "aws_access_key" {
  type = any
}

variable "aws_secret_key" {
  type = any
}

variable "namespace" {
  type    = string
  default = "test"
}

# ###########################
# AWS Networking variables
# ###########################

variable "vpc_cidr_block" {
  type        = string
  description = "Default cidr block for aws vpc"
}


variable "access_ip" {
  type    = string
  default = "0.0.0.0/0"
}

# ###########################
# AWS Compute EC2 variables
# ###########################

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "main_vol_size" {
  type    = number
  default = 20
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "key_name" {
  type = string
}

variable "public_key_path" {
  type = string
}
