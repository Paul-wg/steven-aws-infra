#!/bin/bash
# Usage: ./connect-ai-host.sh dev   or   ./connect-ai-host.sh prod

AWS_PROFILE="ai-steven"
AWS_REGION="ap-southeast-4"
ENVIRONMENT="${1:-dev}"
TAG_VALUE="nebulas-${ENVIRONMENT}"

echo "=========================================="
echo "Connecting to EC2 with tag Name=$TAG_VALUE"
echo "=========================================="
echo

# Get instance ID by tag
echo "Looking up instance ID..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$TAG_VALUE" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text \
  --profile $AWS_PROFILE \
  --region $AWS_REGION)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "ERROR: No running instance found with tag Name=$TAG_VALUE"
    echo
    echo "Please check:"
    echo "1. Instance is running"
    echo "2. Tag Name=$TAG_VALUE exists"
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
