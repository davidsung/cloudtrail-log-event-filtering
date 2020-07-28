variable "environment" {
  description = "Environment"
  default = "staging"
}

variable "aws_region" {
  default = "ap-southeast-1"
}

// CloudTrail
variable "cloudtrail_name" {
  description = "CloudTrail Name"
  default = "cloudtrail"
}

variable "cloudtrail_s3_key_prefix" {
  description = "CloudTrail S3 Bucket Prefix"
  default = "cloudtrail"
}

variable "cloudtrail_event_processor_name" {
  description = "CloudTrail Event Processor Lambda Function Name"
  default = "cloudtrail-event-processor"
}

variable "cloudtrail_event_source_to_track" {
  description = "Event Source Filter"
  default = ".amazonaws.com"
}

// Required Parameters
variable "cloudtrail_s3_bucket_name" {
  description = "CloudTrail S3 Bucket Name"
}

variable "rds_s3_bucket_name" {
  description = "RDS Audit Log S3 Bucket Name"
}

// VPC
variable "vpc_name" {
  description = "VPC Name"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
}
