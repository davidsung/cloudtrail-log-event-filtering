# Output values
output "cloudtrail_arn" {
  value = aws_cloudtrail.cloudtrail.arn
}

output "cloudtrail_log_bucket_name" {
  value = aws_s3_bucket.cloudtrail_log_bucket.id
}

output "rds_log_bucket_name" {
  value = aws_s3_bucket.rds_log_bucket.id
}
