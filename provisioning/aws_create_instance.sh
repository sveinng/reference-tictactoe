#!/bin/bash
#
# Provision AWS ec2 instance and pull docker images to run TicTacToe
#
# The following AWS OS images are available
# ami-0d77397e -> Ubuntu Server 16.04 LTS (HVM), SSD Volume Type
# ami-9398d3e0 -> Amazon Linux AMI 2016.09.0 (HVM), SSD Volume Type


###############################################################################################
# Logging functions
###############################################################################################

abort() {
  log "***************  AWS PROVISIONING ABORTED  ***************"
  exit 1
}

log() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") - $1" | tee -a provision.log
}

wait() {
  let WAIT=0
  STATUS="pending"
  log "Waiting for AWS ec2 instance to start serving HTTP requests @ $1 (max 10 min)"
  curl --connect-timeout 2 -sI http://${1} | grep "200 OK" > /dev/null 2>&1
  while [[ $? -ne 0 ]] ; do
    if [[ $WAIT -gt $MAX_WAIT ]] ; then
      log "ERR  Gave up waiting for AWS ec2 instance @ $1"
      abort
    fi
    sleep 13 ; let WAIT=$WAIT+15
    log "Waiting for AWS ec2 ... $WAIT sec"
    curl --connect-timeout 2 -sI http://${1} | grep "200 OK" > /dev/null 2>&1
  done
  log "AWS ec2 instance is serving HTTP @ $1 (yeah!)"
}


###############################################################################################
# Check current working directory
###############################################################################################

# Get current rundir (where script is executed from)
RUNDIR=$(dirname $0)

# We want to run inside the provisioning directory
[ $RUNDIR != "." ] && cd "$RUNDIR"


###############################################################################################
# Config part
###############################################################################################

# Instance type - the free type is t2.micro - 1 GB Ram - 1 vCPU
INSTANCE_TYPE="t2.micro"

# Private key name (for ssh)
KEY_NAME="ttt-server"

# Subnet id - name says it
SUBNET_ID="subnet-2b47105d"

# Security group - sg-81d35ee7 has tcp/22 and tcp/8080 open for public
SEC_GRP_ID="sg-81d35ee7"

# User data - file containing the boostrap scripts injected to newly created image
USER_DATA="file://aws_bootstrap-$$.sh"

# Max wait (in sec) for http to become ready
MAX_WAIT=600

# Allocation ID - id of Elastic IP -
# PROD eipalloc-a5ffd0c1 has the public IP : 52.209.246.223
# TEST eipalloc-cc4963a8 has the public IP : 52.19.160.110
PROD_ALLOCATION_ID="eipalloc-a5ffd0c1"
TEST_ALLOCATION_ID="eipalloc-cc4963a8"

# AWS tags for new instance - type:ttt-server is default for all TicTacToe servers
AWS_TAG1="Key=type,Value=ttt-server"
#
PROD_AWS_TAG="Key=role,Value=prod"
PROD_AWS_NAME="Key=Name,Value=TTT_PROD"
#
TEST_AWS_TAG="Key=role,Value=test"
TEST_AWS_NAME="Key=Name,Value=TTT_TEST"

# AWS OS Images
UBUNTU="ami-0d77397e"
AWSLINUX="ami-9398d3e0"


###############################################################################################
# CLI part
###############################################################################################

if [[  $# -lt 3 || $# -gt 4 ]] ; then
  printf "\n\t usage $0 <git revision> <ubuntu|awslinux> <test|prod> [wait]"
  printf "\n\t git revision: use full git revision string or latest for latest git revision"
  printf "\n\t aws image id: available images are"
  printf "\n\t\t ubuntu   = ami-0d77397e -> Ubuntu Server 16.04 LTS (HVM), SSD Volume Type"
  printf "\n\t\t awslinux = ami-9398d3e0 -> Amazon Linux AMI 2016.09.0 (HVM), SSD Volume Type"
  printf "\n\n\t\t wait - wait for ec2 instance to become ready (optiona)"
  printf "\n\n"
  exit
fi

GIT_REV=$1
IMAGE=$2
OP_MODE=$3
if [ $# -eq 4 ] ; then
  EC2_WAIT=$4
else
  EC2_WAIT="undef"
fi


###############################################################################################
# Validate input ( check if git tag and docker tag really exists - check for valid os image )
###############################################################################################

# Validate OS image
if [ $IMAGE == "ubuntu" ] ; then
  IMAGE_ID=$UBUNTU
elif [ $IMAGE == "awslinux" ] ; then
  IMAGE_ID=$AWSLINUX
else
  echo "Unknown OS image"
  echo "Valid images are: ubuntu / awslinux"
  abort
fi

# Validate operating mode (test/prod)
if [ $OP_MODE == "test" ] ; then
    ALLOCATION_ID=$TEST_ALLOCATION_ID
    AWS_TAG2=$TEST_AWS_TAG
    AWS_NAME=$TEST_AWS_NAME
    HOST="test.tictactoe.sveinng.com"
elif [ $OP_MODE == "prod" ] ; then
    OP_MODE=production
    ALLOCATION_ID=$PROD_ALLOCATION_ID
    AWS_TAG2=$PROD_AWS_TAG
    AWS_NAME=$PROD_AWS_NAME
    HOST="tictactoe.sveinng.com"
else
    echo "Unknown operation mode!"
    echo "Valid modes are: prod / test"
    abort
fi


log "===============  AWS PROVISIONING STARTED  ==============="
log "Creating $INSTANCE_TYPE $OP_MODE instance from $IMAGE_ID running sveinn/tictactoe:$GIT_REV"

# Check if GIT tag really exists in git
# Use curl to github instead of git commands for portability - this way we test can be run from anywhere
if [ $GIT_REV == "latest" ] ; then
  GIT_REV=$(git ls-remote  https://github.com/sveinng/reference-tictactoe HEAD | cut -f1)
  log "Latest git revision is : $GIT_REV"
else
  if ! curl -sI https://github.com/sveinng/reference-tictactoe/commit/$GIT_REV | grep "200 OK" > /dev/null 2>&1 ; then
    log "ERR  git revision not valid"
    abort
  else
    log "Git revision validated"
  fi
fi


# Check if docker repo has image with given tag
# Use curl to docker hub for portability - this way test can be run from anywhere
curl -si https://registry.hub.docker.com/v2/repositories/sveinn/tictactoe/tags/$GIT_REV/|grep "200 OK" > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  log "Docker repo image found"
else
  log "ERR  Docker repo does not contain image with tag: $GIT_REV"
  log "ERR  Did you forget to run build-docker.sh after doing a git push?"
  abort
fi


# Check if bootstrap template exists for os image id
if [ -e template/*.$IMAGE_ID ] ; then
  log "Valid AWS Image"
else
  log "ERR  Invalid AWS image ID"
  abort
fi


###############################################################################################
# Running part
###############################################################################################

# Create bootstrap script for give image
sed s/GIT_COMMIT_PLACEHOLDER/${GIT_REV}/g template/aws_bootstrap.$IMAGE_ID > aws_bootstrap-$$.tmp
sed s/OP_MODE/${OP_MODE}/g aws_bootstrap-$$.tmp > aws_bootstrap-$$.sh


# Create ec2 instance and collect results
RESULT_INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --subnet-id $SUBNET_ID --security-group-ids $SEC_GRP_ID --user-data $USER_DATA --output text --query 'Instances[*].InstanceId')
if [[ $? -ne 0 ]] ; then
  log "ERR  Error while creating ec2 instance!"
  abort
else
  log "AWS ec2 instance created - id $RESULT_INSTANCE_ID created"
fi


# Gather info on new ec2 instance
RESULT_IMAGE=$(aws ec2 describe-instances --instance-ids $RESULT_INSTANCE_ID --output text --query 'Reservations[0].Instances[0].ImageId')
TMP_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $RESULT_INSTANCE_ID --output text --query 'Reservations[0].Instances[0].PublicIpAddress')


# Double check to see if new ec2 instance was created from correct image
if [[ $RESULT_IMAGE == $IMAGE_ID ]] ; then
  log "AWS ec2 instance verified with correct image - id $RESULT_IMAGE"
else
  log "ERR  AWS ec2 instance created with wrong image - id $RESULT_IMAGE - something went wrong!"
  abort
fi


# Wait for ec2 machine until it is operational
log "Waiting for AWS ec2 instance to enter running state (max 10 min)"
RES=$(aws ec2 wait instance-running --instance-ids $RESULT_INSTANCE_ID)
if [[ $? -ne 0 ]] ; then
  log "ERR  Something went wrong waiting for ec2 machine to enter running state"
  abort
else
  log "AWS ec2 instance has entered running state"
fi


# Wait for ec2 instance to start serving http
if [ $EC2_WAIT == "wait" ] ; then
  wait $TMP_PUBLIC_IP
else
  log "It will be fully upgraded and operating within 4 minutes"
  log "Use the following command to monitor the setup process"

  if [ $IMAGE_ID == "ami-0d77397e" ] ; then
    log "To connect: ssh -i ~/.ssh/ttt-server.pem -l ubuntu -o StrictHostKeyChecking=no $TMP_PUBLIC_IP"
  else
    log "To connect: ssh -i ~/.ssh/ttt-server.pem -l ec2-user -o StrictHostKeyChecking=no $TMP_PUBLIC_IP"
  fi
fi


# Assign Elastic IP to newly created ec2 instance
RES=$(aws ec2 associate-address --instance-id $RESULT_INSTANCE_ID --allocation-id $ALLOCATION_ID)
if [[ $? -ne 0 ]] ; then
  log "ERR  Something went wrong ... Could not attach public IP to AWS ec2 instance : $RESULT_INSTANCE_ID"
  log "ERR  $RES"
  abort
else
  log "Instance assigned to Elastic IP"
fi

# Verify Elastic IP is activated
if [ $EC2_WAIT == "wait" ] ; then
  wait $HOST
else
  if [ $IMAGE_ID == "ami-0d77397e" ] ; then
    log "To connect: ssh -i ~/.ssh/ttt-server.pem -l ubuntu -o StrictHostKeyChecking=no $HOST"
  else
    log "To connect: ssh -i ~/.ssh/ttt-server.pem -l ec2-user -o StrictHostKeyChecking=no $HOST"
  fi
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


# Verify current external IP address
IP=$(aws ec2 describe-instances --instance-ids $RESULT_INSTANCE_ID --output text --query 'Reservations[0].Instances[0].PublicIpAddress')
log "Successfully created AWS ec2 instance: $RESULT_INSTANCE_ID @ $IP"


# Remove bootstrap files
rm aws_bootstrap-$$.tmp aws_bootstrap-$$.sh

log "==============  AWS PROVISIONING SUCCESSFUL  =============="
exit 0
