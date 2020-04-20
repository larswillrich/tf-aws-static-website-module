# Overview and motivation
It seems very easy to host a static website on AWS using a S3 bucket. Nevertheless, if you want to use SSL and a CDN (for TLS offloading and maybe more features), it comes more complex. This motivated me to write a terraform module and provides you a all out-of-the-box a AWS Set Up. This terraform module capsules all necessary ressources you need to host a static website on AWS with following ressources:
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

# Costs
Many people may wonder what this costs. Here is a roughly estimation.
* Cloudfront: Using cloud front you will be charged on-demand. But this is comparatively cheap. (ref: https://aws.amazon.com/cloudfront/pricing/)
  * Regional Data Transfer Out to Internet (per GB): max $0.140 per GB (for the first 10GB)
  * Regional Data Transfer Out to Origin (per GB): max $0.160 per GB
  * Request Pricing for All HTTP Methods (per 10,000): max $0.0220 per 10.000 requests.
* S3: You pay for storage, per requests and for accessibility (ref: https://aws.amazon.com/s3/pricing/)
  * Storage: First 50 TB / Month	$0.023 per GB
  * Requests: S3 Standard	max $0.005 per 1.000 requests. (HTTP GET method only $0.0004 per 1.0000)
  * Data transfer for free to cloudfront 
* ACM: per issued certificate 1 - 1,000	costs $0.75 per certificate.
* Route53: 
  * $0.50 per hosted zone / month for the first 25 hosted zones
  * $0.40 per million queries - first 1 Billion queries / month

Also you need to have a domain and to pay for it. It's depends on the domain how much you pay for this per year. Mostly something between 10 and 30 euro in a year, if this is not a super fany domain.

To sum up, to use these AWS products you pay as you go. When you're just hosting a website with not a lot traffic, so just say <1.000-10.000 requests, the most expensive things seems to be the certificate and the hosted zone (as one time costs each month). So in sum the costs should be under $2 (+ domain costs) in a month.

Please have in mind: No responsibility is taken for the correctness of this information. All information is subject to change.
