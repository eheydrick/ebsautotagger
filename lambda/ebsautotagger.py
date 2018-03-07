#
# ebsautotagger
#
# Tag EBS volumes created by autoscaling
#

import boto3
import os
from time import sleep

ec2 = boto3.client('ec2')


def create_tag(resource, key, value):
    ec2.create_tags(
        Resources=[resource],
        Tags=[
            {
                'Key': key,
                'Value': value
            }]
    )


def lambda_handler(event, _context):
    instance_id = event['detail']['EC2InstanceId']

    # give time for instance tags to propagate
    sleep(5)

    instance_details = ec2.describe_instances(InstanceIds=[instance_id])['Reservations'][0]['Instances'][0]
    environment = (i for i in instance_details['Tags'] if i['Key'] == 'environment').next()['Value']
    service = (i for i in instance_details['Tags'] if i['Key'] == 'service').next()['Value']

    if service.startswith(os.environ.get('SERVICE_TAG_VALUE')):
        for block in instance_details['BlockDeviceMappings']:
            if block['DeviceName'] != "/dev/sda1":
                volume_id = block['Ebs']['VolumeId']
                create_tag(volume_id, 'service', 'myservice')
                create_tag(volume_id, 'environment', environment)
                create_tag(volume_id, 'Name', environment + '-' + service)
