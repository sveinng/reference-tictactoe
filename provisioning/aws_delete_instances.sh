#!/bin/bash
#
# Delete AWS ec2 instance based on environment
# Valid environments are test/prod
#


if [[  ! $# -eq 1 ]] ; then
  printf "\n\t usage $0 <test|prod>\n\n"
  printf "*** WARNING *** This command deletes all ec2 instances in given environment"
fi

ENV=$1

# Validate environment
if [[ $ENV = "test" || $ENV = "prod" ]] ; then
  IDS=$(aws ec2 describe-instances --filters "Name=tag:role,Values=${ENV}" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId')
  for ID in $IDS ; do
    aws ec2 terminate-instances --instance-ids "$ID" --output text --query 'TerminatingInstances[*].CurrentState.Name'
  done
else
  echo "ERR - invalid environment"
  echo "Valid environments are:  prod / test"
  exit 1
fi
