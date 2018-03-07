# ebsautotagger

Tag EBS volumes created by autoscaling.

Currently there is no way for EC2 autoscaling to tag EBS volumes when they are
created. The ebsautotagger lambda function will automatically add tags to EBS
volumes as autoscaling launches the instances. A [Cloudwatch Events](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/WhatIsCloudWatchEvents.html)
rule is used to invoke the lambda. It will tag all non-root EBS volume with the
tags you specify in the lambda function.

## Usage

You will most certainly need to adjust the lambda function to meet your needs. The
example function will add a few sample tags. It looks for an instance tag called
`service` with a value defined in the environment variable `SERVICE_TAG_VALUE`.
You will want to adjust this for your environment or replace it with something that
makes more sense for you.

The `terraform` directory contains terraform code that sets everything up. This
terraform will do the following:

  1. Deploy lambda function
  1. Create Cloudwatch Rule that invokes the lambda function when autoscaling
     launches instances.
  1. Create all the required IAM permissions

