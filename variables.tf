variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "eu-central-1"
}

# S3 Bucket für statische Webseite
variable "bucket_name" {
  description = "S3 bucket name for static website"
  type        = string
  default     = "alina-aws-cloud-project-bucket"
}

# VPC und Subnets
variable "vpc_cidr" {
  description = "CIDR block for the project VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# A
variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

# B
variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

