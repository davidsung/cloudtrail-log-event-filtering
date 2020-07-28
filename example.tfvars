environment = "staging"
aws_region  = "ap-northeast-1"

// CloudTrail
cloudtrail_s3_bucket_name        = "anycompany-cloudtrail-log-bucket"
rds_s3_bucket_name               = "anycompany-rds-log-bucket"
cloudtrail_event_source_to_track = "rds.amazonaws.com"

// VPC
vpc_name = "vpc"
vpc_cidr = "10.0.0.0/16"
