data "aws_route53_zone" "Cloudman" {
  name = "cloudman.pro"
}

data "aws_cloudfront_origin_request_policy" "policy_allviewerexcepthostheader" {
  name = "Managed-AllViewerExceptHostHeader"
}

data "aws_cloudfront_cache_policy" "policy_cachingdisabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "policy_cachingoptimized" {
  name = "Managed-CachingOptimized"
}

data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing_ipv6" {
  name = "com.amazonaws.global.ipv6.cloudfront.origin-facing"
}
