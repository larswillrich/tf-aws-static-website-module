
# besed on restriction described here https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html
# we need to use a us provider for the certificates between viewer and cloudfront
provider "aws" {
  alias = "acm"
  region = "us-east-1"
}

# all other ressources can be generated in europa zone
provider "aws" {
  region  = "eu-central-1"
}

# s3 bucket for hosting our static website
resource "aws_s3_bucket" "static-website-bucket" {
  bucket = var.domain
  acl    = "public-read"
  policy = <<EOF
{
    "Version":"2012-10-17",
    "Statement":[{
      "Sid":"PublicReadGetObject",
          "Effect":"Allow",
        "Principal": "*",
        "Action":["s3:GetObject"],
        "Resource":["arn:aws:s3:::${var.domain}/*"
        ]
      }
    ]
  }
  EOF

  website {
    index_document = "index.html"
    error_document = "error.html"

    routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF
  }
}

# DNS
resource "aws_route53_zone" "main" {
  name = var.domain
}

resource "aws_route53_record" "root_domain" {
  zone_id = aws_route53_zone.main.zone_id
  name = var.domain
  type = "A"

  alias {
    name    = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website-ns" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "NS"
  ttl     = "172800"

  records = [
    "${aws_route53_zone.main.name_servers.0}",
    "${aws_route53_zone.main.name_servers.1}",
    "${aws_route53_zone.main.name_servers.2}",
    "${aws_route53_zone.main.name_servers.3}",
  ]
}

# our certificate
resource "aws_acm_certificate" "cert" {
  provider = aws.acm
  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# certificatin validatin is made by DNS
resource "aws_route53_record" "cert_validation" {
  provider = aws.acm
  name    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  zone_id = aws_route53_zone.main.id
  records = [aws_acm_certificate.cert.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "website" {
  provider = aws.acm
  certificate_arn = aws_acm_certificate.cert.arn

  validation_record_fqdns = [
    aws_route53_record.cert_validation.fqdn
  ]
}

resource "aws_cloudfront_origin_access_identity" "default" {
  comment = ""
}

# CDN
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
    domain_name = aws_s3_bucket.static-website-bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.static-website-bucket.id
  }

  aliases = [var.domain]

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.default_root_object

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    // This needs to match the `origin_id` above.
    target_origin_id       = aws_s3_bucket.static-website-bucket.id
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_200"

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}