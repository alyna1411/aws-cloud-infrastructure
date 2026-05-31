# S3 Bucket Erstellung
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.bucket_name
}
# Verschlüsselte Datenspeicherung 
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.website_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
# Upload der HTML-file in den S3 Bucket
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  content_type = "text/html"
}
# CloudFront Distribution und Zugriffskontrolle
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac-website"
  description                       = "OAC for private S3 website bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
resource "aws_cloudfront_distribution" "website_cdn" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }
  # HTTPS erzwingen und nur GET/HEAD erlauben
  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # Keine geografischen Einschränkungen
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Standard-CloudFront-Zertifikat
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront_access" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"

        Principal = {
          Service = "cloudfront.amazonaws.com"
        }

        Action = "s3:GetObject"

        Resource = "${aws_s3_bucket.website_bucket.arn}/*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_cdn.arn
          }
        }
      }
    ]
  })
}

# Virtual Private Cloud (VPC) Erstellung
resource "aws_vpc" "project_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "project-igw"
  }
}

# Subnet A
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
  }
}

# Subnet B
resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
  }
}

# Routing
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security Group für ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security Group fuer den Application Load Balancer"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Security Group für EC2
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Security Group fuer EC2 Instanzen"
  vpc_id      = aws_vpc.project_vpc.id

  # Nur Traffic vom ALB erlauben
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# Application Load Balancer (ALB)
resource "aws_lb" "project_alb" {
  name               = "project-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id
  ]

  tags = {
    Name = "project-alb"
  }
}

# Target group
resource "aws_lb_target_group" "project_tg" {
  name     = "project-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "project-tg"
  }
}

# Listener (Port 80)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.project_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project_tg.arn
  }
}

# EC2 und Launch Template
resource "aws_launch_template" "project_lt" {
  name_prefix   = "project-lt-"
  image_id      = "ami-0f1834be8d049e69f"
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Hello from EC2 - $(hostname)</h1>" > /var/www/html/index.html
  EOF
  )

  tags = {
    Name = "project-launch-template"
  }
}

# Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "project_asg" {
  name              = "project-asg"
  desired_capacity  = 2
  min_size          = 1
  max_size          = 3
  target_group_arns = [aws_lb_target_group.project_tg.arn]
  vpc_zone_identifier = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id
  ]

  launch_template {
    id      = aws_launch_template.project_lt.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "project-ec2"
    propagate_at_launch = true
  }
}

# IAM Rolle für EC2 Instanzen
resource "aws_iam_role" "ec2_role" {
  name = "ec2-project-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "ec2-project-role"
  }
}

# IAM Policy
resource "aws_iam_role_policy" "ec2_secrets_policy" {
  name = "ec2-secrets-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "*"
    }]
  })
}

# IAM Instanz-Profil
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-project-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "ec2-project-profile"
  }
}

# Secrets Manager
resource "aws_secretsmanager_secret" "project_secret" {
  name        = "project/app-secret-v2"
  description = "Application secrets for the project"

  tags = {
    Name = "project-app-secret"
  }
}

resource "aws_secretsmanager_secret_version" "project_secret_value" {
  secret_id = aws_secretsmanager_secret.project_secret.id

  secret_string = jsonencode({
    app_env = "production"
    app_key = "placeholder-key-replace-in-production"
  })
}

# Route 53 Hosted Zone
resource "aws_route53_zone" "project_zone" {
  name = "alina-aws-cloud-project.internal"

  tags = {
    Name = "alina-aws-cloud-project-zone"
  }
}

# zeigt auf ALB
resource "aws_route53_record" "alb_record" {
  zone_id = aws_route53_zone.project_zone.zone_id
  name    = "www.alina-aws-cloud-project.internal"
  type    = "A"

  alias {
    name                   = aws_lb.project_alb.dns_name
    zone_id                = aws_lb.project_alb.zone_id
    evaluate_target_health = true
  }
}