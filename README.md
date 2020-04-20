# Overview and motivation
This terraform module capsules all necessary ressources you need to host a static website on AWS with following ressources:
* S3 bucket for hosting your page
* AWS ACM for providing a certificate to be able to have a secure connectian via https
* Cloudfront as our CDN
* DNS via Route53 to have a nameserver with a zone and some records

# Prerequirements
All you need is Terraform v0.12 and an AWS account.

# How to use the module?
Here is an example how to use the module:  
```
module "static-website" {
  source              = "github.com/larswillrich/tf-aws-static-website-module"
  domain              = "yourdomain.com"
  default_root_object = "index.html"
}
```