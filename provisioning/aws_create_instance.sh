#!/bin/bash
#
# Create AWS instance with Ubuntu 16.04 image and bootstrap with aws_bootstrap.sh script
#

###############################################################################################
# Config part

# OS image to use - ami-0d77397e is Ubuntu 16.04 64-bit
IMAGE_ID="ami-0d77397e"

# Number of instances to create
COUNT=1

# Instance type - the free type is t2.micro - 1 GB Ram - 1 vCPU
INSTANCE_TYPE="t2.micro"

# Private key name (for ssh)
KEY_NAME="ttt-server"

# Subnet id - name says it
SUBNET_ID="subnet-2b47105d"

# Security group - sg-81d35ee7 has tcp/22 and tcp/8080 open for public
SEC_GRP_ID="sg-81d35ee7"

# User data - file containing the boostrap scripts injected to newly created image
USER_DATA="file://aws_bootstrap.sh"

# Allocation ID - id of Elastic IP - eipalloc-a5ffd0c1 has the public IP : 52.209.246.223
ALLOCATION_ID="eipalloc-a5ffd0c1"

# Max wait time for instance to become running - Each TRY equals 5 seconds -> 12 try = 60 sec
MAX_TRY=12


###############################################################################################
# Running part

# Create ec2 instance and collect results
RES=$(aws ec2 run-instances --image-id $IMAGE_ID --count $COUNT --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --subnet-id $SUBNET_ID --security-group-ids $SEC_GRP_ID --user-data $USER_DATA)

# Gather info from ec2 create output
RESULT_IMAGE=$(echo "$RES" | awk '/^INSTANCE/ {print $6}')
RESULT_INSTANCE_ID=$(echo "$RES" | awk '/^INSTANCE/ {print $7}')

# Double check to see if new ec2 instance was created from correct image
if [[ $RESULT_IMAGE = $IMAGE_ID ]] ; then
  echo "*** ec2 instance created"
else
  echo "*** ec2 instance created with strange image id: $RESULT_IMAGE - something went wrong!"
  echo "...abort..."
  exit 1
fi


let TRY=0
STATUS="pending"
echo "*** waiting for instance to enter running state"
printf "*** "

while [[ $STATUS != "running" ]] ; do
  sleep 5
  STATUS=$(aws ec2 describe-instance-status --instance-ids $RESULT_INSTANCE_ID | awk  '/^INSTANCESTATE/ {print $3}')
  if [[ $TRY -gt $MAX_TRY ]] ; then
    echo "*** Gave up waiting for ec2 instance"
    echo "...abort..."
    exit 2
  fi
  let TRY=$TRY+1
  printf ":"
done

echo
echo "*** ec2 instance has entered running state"


# Assign Elastic IP to newly created ec2 instance
RES=$(aws ec2 associate-address --instance-id $RESULT_INSTANCE_ID --allocation-id $ALLOCATION_ID)
if [[ $? -ne 0 ]] ; then
  echo "*** Something went wrong ... Could not attach public IP to ec2 instance : $RESULT_INSTANCE_ID"
  echo "*** $RES"
  exit 3
else
  echo "*** Instance assigned to public ip : 52.209.246.223"
fi


echo "*** Successfully created ec2 instance: $RESULT_INSTANCE_ID @ 52.209.246.223"
echo "*** It should be fully upgraded and operating in 4-5 minutes"

exit 0
