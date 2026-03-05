#!/bin/bash
# Connect to EC2 via SSM using tag name=Nebulas-host

AWS_PROFILE="ai-steven"
AWS_REGION="ap-southeast-4"
TAG_NAME="Nebulas-host"

echo "=========================================="
echo "Connecting to EC2 with tag name=$TAG_NAME"
echo "=========================================="
echo

# Get instance ID by tag
echo "Looking up instance ID..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:name,Values=$TAG_NAME" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text \
  --profile $AWS_PROFILE \
  --region $AWS_REGION)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "ERROR: No running instance found with tag name=$TAG_NAME"
    echo
    echo "Please check:"
    echo "1. Instance is running"
    echo "2. Tag name=Nebulas-host exists"
    echo "3. AWS profile and region are correct"
    exit 1
fi

echo "Found instance: $INSTANCE_ID"
echo
echo "Starting SSM session..."
echo "=========================================="
echo

aws ssm start-session \
  --target $INSTANCE_ID \
  --profile $AWS_PROFILE \
  --region $AWS_REGION
