resource "aws_s3_bucket" "website_bucket" {
  bucket = "alina-aws-cloud-project-bucket"
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  content_type = "text/html"
}
