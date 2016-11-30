#!/bin/bash

#
# Create AWS instance with Ubuntu 16.04 image and bootstrap with aws_bootstrap.sh script
#

aws ec2 run-instances --image-id ami-0d77397e --count 1 --instance-type t2.micro --key-name ttt-server \
--user-data $(base64 aws_bootstrap.sh) --subnet-id subnet-2b47105d --security-group-ids sg-81d35ee7
