terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_iam_policy_document" "web_hosting_policy" {
  statement {
    sid = "PublicReadGetObject"

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    actions = ["s3:GetObject"]

    resources = ["arn:aws:s3:::${aws_s3_bucket.dns_host_bucket.id}/*"]
  }
}


####################################################################
#                                                                  #
# AMAZON WEB SERVICES | ROUTE 53                                   #
#                                                                  #
#                                                                  #
# Providing resource for my registered domain name through AWS     #
# Route53 to have as a refrence for other resource configurations. #
####################################################################

resource "aws_route53domains_registered_domain" "vsubtle" {
  domain_name = "vsubtle.com"
}

resource "aws_route53_record" "vsubtle_IPv4" {
  zone_id = "Z0812073WY8PD36ECG6J"
  name    = "vsubtle.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "vsubtle_IPv6" {
  zone_id = "Z0812073WY8PD36ECG6J"
  name    = "vsubtle.com"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


###################################################################
#                                                                 #
# AMAZON WEB SERVICES | S3 BUCKET                                 #
#                                                                 #
#                                                                 #
# Setting up AWS S3 Bucket with website hosting configuration     #
# and uploading HTML/CSS/JS files. Also allows all public access. #
###################################################################

# Creates S3 bucket with the name "vsubtle.com"
resource "aws_s3_bucket" "dns_host_bucket" {
  bucket = "vsubtle.com"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

# S3 Bucket configuration so allow static website hosting.
resource "aws_s3_bucket_website_configuration" "dns_host_bucket" {
  bucket = aws_s3_bucket.dns_host_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# S3 Bucket configuration to allow all public access.
resource "aws_s3_bucket_public_access_block" "make_public" {
  bucket = aws_s3_bucket.dns_host_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Policy to allow public acess to items in
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket_public_access_block.make_public.id
  policy = data.aws_iam_policy_document.web_hosting_policy.json
}

# Uploading "index.html" file to created S3 Bucket.
resource "aws_s3_object" "index_file" {
  bucket       = aws_s3_bucket.dns_host_bucket.id
  key          = "index.html"
  source       = "./index.html"
  content_type = "text/html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("./index.html")
}

# Uploading "style.css" file to created S3 Bucket.
resource "aws_s3_object" "stylecss_file" {
  bucket       = aws_s3_bucket.dns_host_bucket.id
  key          = "style.css"
  source       = "./style.css"
  content_type = "text/css"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("./style.css")
}

# Uploading "logic.js" file to created S3 Bucket.
resource "aws_s3_object" "logic_file" {
  bucket       = aws_s3_bucket.dns_host_bucket.id
  key          = "logic.js"
  source       = "./logic.js"
  content_type = "application/x-javascript"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("./logic.js")
}


###################################################################
#                                                                 #
# AMAZON WEB SERVICES | CLOUDFRONT                                #
#                                                                 #
#                                                                 #
# Setting up AWS CloudFront Distribution with appropiate          #
# configuration and SSL certificate for custom domain name.       #
###################################################################

# Creates CloudFront distribution with S3 bucket origin and custom SSL Certificate
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.dns_host_bucket.website_endpoint
    origin_id   = aws_s3_bucket.dns_host_bucket.id

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = "${aws_api_gateway_rest_api.MyResumeAPI.id}.execute-api.us-east-1.amazonaws.com"
    origin_id   = aws_api_gateway_rest_api.MyResumeAPI.id
    origin_path = "/v5"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = ["vsubtle.com"]

  default_cache_behavior {
    # Using the CachingOptimized managed policy ID:
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.dns_host_bucket.id

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/lambda"
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_api_gateway_rest_api.MyResumeAPI.id

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    viewer_protocol_policy = "https-only"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    # Using the CachingOptimized managed policy ID:
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    path_pattern = "*"
    target_origin_id = aws_s3_bucket.dns_host_bucket.id

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:217795762442:certificate/fb9f5654-327a-452e-8963-25e2479d620d"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}


###################################################################
#                                                                 #
# AMAZON WEB SERVICES | DYNAMO DB                                 #
#                                                                 #
#                                                                 #
# Setting up AWS DynamDB to store the visitor count that my       #
# static site will pull from to update the value on the page.     #
###################################################################

# Creates DynamoDB table with sort key "User" amd one attribute 
resource "aws_dynamodb_table" "resume-dynamodb-table" {
  name         = "visit-count-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user"

  attribute {
    name = "user"
    type = "S"
  }
}


######################################################################
#                                                                    #
# AMAZON WEB SERVICES | API GATEWAY                                  #
#                                                                    #
#                                                                    #
# Setting up an AWS API Gateway resource that will take requests     #
# from static site to trigger my Lambda function to update the       #
# DynamoDB.                                                          #
######################################################################

# Creating REST API rsource
resource "aws_api_gateway_rest_api" "MyResumeAPI" {
  name        = "resume-api"
  description = "This is the resume api to accept requests from my front-end."
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Creating the the lambda path resource
resource "aws_api_gateway_resource" "LambdaPath" {
  rest_api_id = aws_api_gateway_rest_api.MyResumeAPI.id
  parent_id   = aws_api_gateway_rest_api.MyResumeAPI.root_resource_id
  path_part   = "lambda"
}

# Adding an OPTIONS method with CORS enabled
resource "aws_api_gateway_method" "MyOptionsMethod" {
  rest_api_id   = aws_api_gateway_rest_api.MyResumeAPI.id
  resource_id   = aws_api_gateway_resource.LambdaPath.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Creating a POST method that will ultimately trigger my Lambda function
resource "aws_api_gateway_method" "MyPostMethod" {
  rest_api_id   = aws_api_gateway_rest_api.MyResumeAPI.id
  resource_id   = aws_api_gateway_resource.LambdaPath.id
  http_method   = "POST"
  authorization = "NONE"
}

# Adding Lambda integration too my OPTIONS method
resource "aws_api_gateway_integration" "lambda_integration_options" {
  rest_api_id             = aws_api_gateway_rest_api.MyResumeAPI.id
  resource_id             = aws_api_gateway_resource.LambdaPath.id
  http_method             = aws_api_gateway_method.MyOptionsMethod.http_method
  integration_http_method = "OPTIONS"
  type                    = "AWS"
  uri                     = aws_lambda_function.resume_lambda.invoke_arn
}

# Adding Lambda integration too my POST method
resource "aws_api_gateway_integration" "lambda_integration_post" {
  rest_api_id             = aws_api_gateway_rest_api.MyResumeAPI.id
  resource_id             = aws_api_gateway_resource.LambdaPath.id
  http_method             = aws_api_gateway_method.MyPostMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.resume_lambda.invoke_arn
}

resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.MyResumeAPI.id
  resource_id = aws_api_gateway_resource.LambdaPath.id
  http_method = aws_api_gateway_method.MyPostMethod.http_method
  status_code = aws_api_gateway_method_response.post_response_200.status_code
  depends_on = [
    aws_api_gateway_method.MyPostMethod,
    aws_api_gateway_integration.lambda_integration_post
  ]
}

resource "aws_api_gateway_method_response" "options_response_200" {
  rest_api_id = aws_api_gateway_rest_api.MyResumeAPI.id
  resource_id = aws_api_gateway_resource.LambdaPath.id
  http_method = aws_api_gateway_method.MyOptionsMethod.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "post_response_200" {
  rest_api_id = aws_api_gateway_rest_api.MyResumeAPI.id
  resource_id = aws_api_gateway_resource.LambdaPath.id
  http_method = aws_api_gateway_method.MyPostMethod.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

# Deployment of my resource with triggers to indentify the methods and integrations needed
resource "aws_api_gateway_deployment" "deploy_resume_api" {
  rest_api_id = aws_api_gateway_rest_api.MyResumeAPI.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.LambdaPath.id,
      aws_api_gateway_method.MyPostMethod.id,
      aws_api_gateway_integration.lambda_integration_post.id,
      aws_api_gateway_method.MyOptionsMethod.id,
      aws_api_gateway_integration.lambda_integration_options.id
    ]))
  }
}

# Creaters a resource to manage a stage name 
resource "aws_api_gateway_stage" "stage_v5" {
  deployment_id = aws_api_gateway_deployment.deploy_resume_api.id
  rest_api_id   = aws_api_gateway_rest_api.MyResumeAPI.id
  stage_name    = "v5"
}


######################################################################
#                                                                    #
# AMAZON WEB SERVICES | LAMBDA                                       #
#                                                                    #
#                                                                    #
# Setting up AWS Lambda resource that will trigger to a response     #
# to a API Gateway call is made to store and retrieve data from      #
# DynamoDB.                                                          #
######################################################################

# Data resource to create the deployment packaage to use with Lambda
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

# Creating Lambda resource with deployment package 
resource "aws_lambda_function" "resume_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = "my-resume-function"
  role          = "arn:aws:iam::217795762442:role/dynamodb_all_role"
  handler       = "lambda_function.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resume_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.MyResumeAPI.execution_arn}/*/*"
}