provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_s3_bucket" "site_bucket" {
  bucket = "donblancco-sideproject-site"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "site_policy" {
  bucket     = aws_s3_bucket.site_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.block_public]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = {
          "AWS" = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.site_bucket.arn}/*"]
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for donblancco-sideproject-site"
}

resource "aws_cloudfront_distribution" "cdn" {
  aliases = ["don-blanc-co.com", "www.don-blanc-co.com"]

  origin {
    domain_name = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.site_bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.site_bucket.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "donblanccoSideprojectCDN"
  }
}

output "site_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}