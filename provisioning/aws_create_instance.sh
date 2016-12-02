#!/bin/bash
#
# Provision AWS ec2 instance and pull docker images to run TicTacToe
#
# The following AWS OS images are available
# ami-0d77397e -> Ubuntu Server 16.04 LTS (HVM), SSD Volume Type
# ami-9398d3e0 -> Amazon Linux AMI 2016.09.0 (HVM), SSD Volume Type


abort() {
  echo "...abort..."
  exit 1
}

###############################################################################################
# Config part

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

# Max wait time for instance to become running in seconds (not counting aws cli runtime)
MAX_WAIT=60


###############################################################################################
# CLI part

if [[ ! $# -eq 2 ]] ; then
  printf "\n\t usage $0 <git revision> <aws image id>"
  printf "\n\t git revision: use full git revision string or latest for latest git revision"
  printf "\n\t aws image id: available images are"
  printf "\n\t\t ami-0d77397e -> Ubuntu Server 16.04 LTS (HVM), SSD Volume Type"
  printf "\n\t\t ami-9398d3e0 -> Amazon Linux AMI 2016.09.0 (HVM), SSD Volume Type"
  printf "\n\n"
  exit
fi

GIT_REV=$1
IMAGE_ID=$2


###############################################################################################
# Validate input

# Check if GIT tag really exists in git
if [ $GIT_REV = "latest" ] ; then
  GIT_REV=$(git rev-parse HEAD)
  echo "*** - Latest git revision is : $GIT_REV"
else
  if ! git rev-list HEAD | grep $GIT_REV >/dev/null 2>&1 ; then
    echo "ERR - git revision not found info revision list"
    abort
  else
    echo "*** - Git revision validated"
  fi
fi


# Check if docker repo has image with given tag
curl -si https://registry.hub.docker.com/v2/repositories/sveinn/tictactoe/tags/$GIT_REV/|grep "200 OK" > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo "*** - Docker repo image found"
else
  echo "ERR - Docker repo does not contain image with tag: $GIT_REV"
  echo "ERR - Did you forget to run build-docker.sh after doing a git push?"
  abort
fi

# Check if bootstrap template exists for id
if [ -e template/*.$IMAGE_ID ] ; then
  echo "*** - Valid AWS Image"
else
  echo "ERR - Invalid AWS image ID"
  abort
fi


###############################################################################################
# Running part

# Create bootstrap script for give image
sed s/GIT_COMMIT_PLACEHOLDER/$GIT_REV/g template/aws_bootstrap.$IMAGE_ID > aws_bootstrap.sh

# Create ec2 instance and collect results
RES=$(aws ec2 run-instances --image-id $IMAGE_ID --count $COUNT --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --subnet-id $SUBNET_ID --security-group-ids $SEC_GRP_ID --user-data $USER_DATA)

# Gather info from ec2 create output
RESULT_IMAGE=$(echo "$RES" | awk '/^INSTANCE/ {print $6}')
RESULT_INSTANCE_ID=$(echo "$RES" | awk '/^INSTANCE/ {print $7}')

# Double check to see if new ec2 instance was created from correct image
if [[ $RESULT_IMAGE = $IMAGE_ID ]] ; then
  echo "*** - ec2 instance created"
else
  echo "ERR - ec2 instance created with strange image id: $RESULT_IMAGE - something went wrong!"
  abort
fi


let WAIT=0
STATUS="pending"
echo "*** - waiting for instance to enter running state"
printf "*** - "

while [[ $STATUS != "running" ]] ; do
  sleep 5 ; let WAIT=$WAIT+5
  STATUS=$(aws ec2 describe-instance-status --instance-ids $RESULT_INSTANCE_ID | awk  '/^INSTANCESTATE/ {print $3}')
  if [[ $WAIT -gt $MAX_WAIT ]] ; then
    echo "ERR - Gave up waiting for ec2 instance"
    abort
  fi
  printf "..$WAIT sec.. "
done

echo
echo "*** - ec2 instance has entered running state"


# Assign Elastic IP to newly created ec2 instance
RES=$(aws ec2 associate-address --instance-id $RESULT_INSTANCE_ID --allocation-id $ALLOCATION_ID)
if [[ $? -ne 0 ]] ; then
  echo "ERR - Something went wrong ... Could not attach public IP to ec2 instance : $RESULT_INSTANCE_ID"
  echo "ERR - $RES"
  abort
else
  echo "*** - Instance assigned to public ip : 52.209.246.223"
fi


echo "*** - Successfully created ec2 instance: $RESULT_INSTANCE_ID @ 52.209.246.223"
echo "*** - It should be fully upgraded and operating in 4-5 minutes"

rm aws_bootstrap.sh
exit 0
