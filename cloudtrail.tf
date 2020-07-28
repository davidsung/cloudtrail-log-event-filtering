resource "aws_cloudtrail" "cloudtrail" {
  name                          = var.cloudtrail_name
  # kms_key_id                    = aws_kms_key.cloudtrail_key.arn
  s3_bucket_name                = aws_s3_bucket.cloudtrail_log_bucket.id
  s3_key_prefix                 = var.cloudtrail_s3_key_prefix
  include_global_service_events = true
}

resource "aws_s3_bucket" "cloudtrail_log_bucket" {
  bucket = var.cloudtrail_s3_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.cloudtrail_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.cloudtrail_s3_bucket_name}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.cloudtrail_s3_bucket_name}/${var.cloudtrail_s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY

  tags = {
    Name        = var.cloudtrail_s3_bucket_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_notification" "cloudtrail_log_bucket_notification" {
  bucket = aws_s3_bucket.cloudtrail_log_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.cloudtrail_event_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${var.cloudtrail_s3_key_prefix}/AWSLogs/"
    filter_suffix       = ".gz"
  }

  depends_on = [aws_lambda_permission.cloudtrail_event_processing]  
}

resource "aws_s3_bucket" "rds_log_bucket" {
  bucket = var.rds_s3_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.cloudtrail_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

# Necessary to provide a bucket policy to grant permission to lambda sitting in different account 
#   policy = <<POLICY
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "AWSCloudTrailWrite",
#             "Effect": "Allow",
#             "Principal": {
#               "AWS": "${aws_iam_role.cloudtrail_event_processor_execution_role.arn}"
#             },
#             "Action": "s3:*",
#             "Resource": "arn:aws:s3:::${var.rds_s3_bucket_name}/${var.cloudtrail_s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
#         }
#     ]
# }
# POLICY

  tags = {
    Name        = var.rds_s3_bucket_name
    Environment = var.environment
  }
} 

resource "aws_kms_key" "cloudtrail_key" {
  description         = "CloudTrail Log Bucket KMS Key"
  enable_key_rotation = true
}