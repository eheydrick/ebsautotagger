resource "aws_iam_role" "ebsautotagger" {
  name = "ebsautotagger"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ebsautotagger" {
  name        = "ebsautotagger"
  description = "Policy for ebsautotagger lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ebsautotagger_role_policy_attachment" {
  role       = "${aws_iam_role.ebsautotagger.name}"
  policy_arn = "${aws_iam_policy.ebsautotagger.arn}"
}

# lambda functions have to be zip'ed up
data "archive_file" "ebsautotagger_zip" {
  type        = "zip"
  source_dir  = "lambda"
  output_path = "/tmp/ebsautotagger.zip"
}

# create the lambda function
resource "aws_lambda_function" "ebsautotagger" {
  function_name    = "ebsautotagger"
  runtime          = "python2.7"
  handler          = "ebsautotagger.lambda_handler"
  role             = "${aws_iam_role.ebsautotagger.arn}"
  timeout          = 20
  filename         = "/tmp/ebsautotagger.zip"
  source_code_hash = "${data.archive_file.ebsautotagger_zip.output_base64sha256}"

  environment {
    variables = {
      SERVICE_TAG_VALUE = "somevalue"
    }
  }
}

# create cloudwatch event rule
resource "aws_cloudwatch_event_rule" "ebsautotagger" {
  name        = "autoscaling-launch-events-to-ebsautotagger"
  description = "Trigger lambda when EC2 autoscaling instances are launched"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance Launch Successful"
  ]
}
PATTERN
}

# invoke lambda when the cloudwatch event rule triggers
resource "aws_cloudwatch_event_target" "invoke-lambda" {
  rule      = "${aws_cloudwatch_event_rule.ebsautotagger.name}"
  target_id = "InvokeLambda"
  arn       = "${aws_lambda_function.ebsautotagger.arn}"
}

# permit cloudwatch event rule to invoke lambda
resource "aws_lambda_permission" "lambda_permissions" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ebsautotagger.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.ebsautotagger.arn}"
}
