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

log() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") - $1" | tee -a provision.log
}



###############################################################################################
# Check current working directory

# Get current rundir (where script is executed from)
RUNDIR=$(dirname $0)

# We want to run inside the provisioning directory
[ $RUNDIR != "." ] && cd "$RUNDIR"


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

# Allocation ID - id of Elastic IP -
# PROD eipalloc-a5ffd0c1 has the public IP : 52.209.246.223
# TEST eipalloc-cc4963a8 has the public IP : 52.19.160.110
PROD_ALLOCATION_ID="eipalloc-a5ffd0c1"
TEST_ALLOCATION_ID="eipalloc-cc4963a8"

# AWS tags for new instance - type:ttt-server & role:production are the current tags
AWS_TAG1="Key=type,Value=ttt-server"
PROD_AWS_TAG="Key=role,Value=prod"
PROD_AWS_NAME="Key=Name,Value=TicTacToe_PROD"
TEST_AWS_TAG="Key=role,Value=test"
TEST_AWS_NAME="Key=Name,Value=TicTacToe_TEST"

# Max wait time for instance to become running in seconds (not counting aws cli runtime)
MAX_WAIT=60


###############################################################################################
# CLI part

if [[ ! $# -eq 3 ]] ; then
  printf "\n\t usage $0 <git revision> <aws image id> <test|production>"
  printf "\n\t git revision: use full git revision string or latest for latest git revision"
  printf "\n\t aws image id: available images are"
  printf "\n\t\t ami-0d77397e -> Ubuntu Server 16.04 LTS (HVM), SSD Volume Type"
  printf "\n\t\t ami-9398d3e0 -> Amazon Linux AMI 2016.09.0 (HVM), SSD Volume Type"
  printf "\n\n"
  exit
fi

GIT_REV=$1
IMAGE_ID=$2
OP_MODE=$3


###############################################################################################
# Validate input

if [ $OP_MODE == "test" ] ; then
    ALLOCATION_ID=$TEST_ALLOCATION_ID
    AWS_TAG2=$TEST_AWS_TAG
    AWS_NAME=$TEST_AWS_NAME
elif [ $OP_MODE = "production" ] ; then
    ALLOCATION_ID=$PROD_ALLOCATION_ID
    AWS_TAG2=$PROD_TAG_TEST
    AWS_NAME=$PROD_AWS_NAME
else
    echo "Unknown operation mode!"
    echo "Valid modes are: production / test"
    abort
fi


log "Creating $COUNT x $INSTANCE_TYPE $OP_MODE instance from $IMAGE_ID running sveinn/tictactoe:$GIT_REV"

# Check if GIT tag really exists in git
if [ $GIT_REV = "latest" ] ; then
  GIT_REV=$(git rev-parse HEAD)
  log "Latest git revision is : $GIT_REV"
else
  if ! git rev-list HEAD | grep $GIT_REV >/dev/null 2>&1 ; then
    log "ERR  git revision not valid"
    abort
  else
    log "Git revision validated"
  fi
fi


# Check if docker repo has image with given tag
curl -si https://registry.hub.docker.com/v2/repositories/sveinn/tictactoe/tags/$GIT_REV/|grep "200 OK" > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  log "Docker repo image found"
else
  log "ERR  Docker repo does not contain image with tag: $GIT_REV"
  log "ERR  Did you forget to run build-docker.sh after doing a git push?"
  abort
fi

# Check if bootstrap template exists for id
if [ -e template/*.$IMAGE_ID ] ; then
  log "Valid AWS Image"
else
  log "ERR  Invalid AWS image ID"
  abort
fi


###############################################################################################
# Running part

# Create bootstrap script for give image
sed s/GIT_COMMIT_PLACEHOLDER/$GIT_REV/g template/aws_bootstrap.$IMAGE_ID > aws_bootstrap.sh
sed -i s/OP_MODE/$OP_MODE/g aws_bootstrap.sh

# Create ec2 instance and collect results
RES=$(aws ec2 run-instances --image-id $IMAGE_ID --count $COUNT --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --subnet-id $SUBNET_ID --security-group-ids $SEC_GRP_ID --user-data $USER_DATA)

# Gather info from ec2 create output
RESULT_IMAGE=$(echo "$RES" | awk '/^INSTANCE/ {print $6}')
RESULT_INSTANCE_ID=$(echo "$RES" | awk '/^INSTANCE/ {print $7}')

# Double check to see if new ec2 instance was created from correct image
if [[ $RESULT_IMAGE = $IMAGE_ID ]] ; then
  log "AWS ec2 instance created"
else
  log "ERR  AWS ec2 instance created with strange image id: $RESULT_IMAGE - something went wrong!"
  abort
fi


let WAIT=0
STATUS="pending"
log "Waiting for instance to enter running state (max $MAX_WAIT sec)"

# Wait for instance to enter the running state
while [[ $STATUS != "running" ]] ; do
  sleep 5 ; let WAIT=$WAIT+5
  STATUS=$(aws ec2 describe-instance-status --instance-ids $RESULT_INSTANCE_ID | awk  '/^INSTANCESTATE/ {print $3}')
  if [[ $WAIT -gt $MAX_WAIT ]] ; then
    log "ERR  Gave up waiting for AWS ec2 instance"
    abort
  fi
  log "..$WAIT sec.. "
done
log "AWS ec2 instance has entered running state"


# Assign Elastic IP to newly created ec2 instance
RES=$(aws ec2 associate-address --instance-id $RESULT_INSTANCE_ID --allocation-id $ALLOCATION_ID)
if [[ $? -ne 0 ]] ; then
  log "ERR  Something went wrong ... Could not attach public IP to AWS ec2 instance : $RESULT_INSTANCE_ID"
  log "ERR  $RES"
  abort
else
  log "Instance assigned to Elastic IP"
fi


# Tag newly created intance
RES=$(aws ec2 create-tags --resources $RESULT_INSTANCE_ID --tags $AWS_TAG1 $AWS_TAG2 $AWS_NAME)
if [[ $? -ne 0 ]] ; then
  log "ERR  Something went wrong ... could not tag newly created instance"
  log "ERR  $RES"
  abort
else
  log "Instance properly tagged"
fi


# Verify current hostname and external IP address
IP=$(aws ec2 describe-instances --instance-ids $RESULT_INSTANCE_ID | awk '/^INSTANCES/ {print $15}')


log "Successfully created AWS ec2 instance: $RESULT_INSTANCE_ID @ $IP"
log "It will be fully upgraded and operating within 4 minutes"
log "Use the following command to monitor the setup process"

if [ $IMAGE_ID = "ami-0d77397e" ] ; then
  log 'To connect: ssh -i ~/.ssh/ttt-server.pem -l ubuntu -o StrictHostKeyChecking=no tictactoe.sveinng.com "tail -f /var/log/cloud-init-output.log"\n'
else
  log 'To connect: ssh -i ~/.ssh/ttt-server.pem -l ec2-user -o StrictHostKeyChecking=no tictactoe.sveinng.com "tail -f /var/log/cloud-init-output.log"\n'
fi

exit 0
