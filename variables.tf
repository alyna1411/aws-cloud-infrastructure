variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "S3 bucket name for static website"
  type        = string
  default     = "alina-aws-cloud-project-bucket"
}

