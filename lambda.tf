data "archive_file" "cloudtrail_event_processor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/cloudtrail-event-processor/"
  output_path = "${path.module}/.artifacts/cloudtrail-event-processor/index.zip"
}

resource "aws_lambda_function" "cloudtrail_event_processor" {
  filename         = "${path.module}/.artifacts/cloudtrail-event-processor/index.zip"
  function_name    = var.cloudtrail_event_processor_name
  role             = aws_iam_role.cloudtrail_event_processor_execution_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.cloudtrail_event_processor_zip.output_base64sha256
  runtime          = "nodejs12.x"
  memory_size      = 256
  timeout          = 300

  environment {
    variables = {
      DST_BUCKET            = aws_s3_bucket.rds_log_bucket.id
      EVENT_SOURCE_TO_TRACK = var.cloudtrail_event_source_to_track
    }
  }
}

resource "aws_lambda_permission" "cloudtrail_event_processing" {
  statement_id  = "cloudtrail_event_processing"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudtrail_event_processor.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.cloudtrail_log_bucket.arn
#   source_account = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role" "cloudtrail_event_processor_execution_role" {
  name     = "cloudtrail-event-processor-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "cloudtrail_event_processor_execution_role_policy" {
  name        = "cloudtrail-event-processor-execution-role-policy"
  description = "CloudTrail Event Processor Execution Role Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.cloudtrail_log_bucket.arn}/*"
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.rds_log_bucket.arn}/*"
    },
    {
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Effect": "Allow",
      "Resource": "${aws_kms_key.cloudtrail_key.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role_attachment" {
  role       = aws_iam_role.cloudtrail_event_processor_execution_role.name
  policy_arn = aws_iam_policy.cloudtrail_event_processor_execution_role_policy.arn
}
