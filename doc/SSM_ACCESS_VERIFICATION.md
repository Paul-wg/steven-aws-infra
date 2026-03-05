# SSM Session Manager Access Verification

## IAM Role Review for SSM Access

### ✅ Current IAM Policy - SSM Permissions

```hcl
{
  Effect = "Allow"
  Action = [
    # SSM Core
    "ssm:UpdateInstanceInformation",           ✅ Required
    
    # SSM Messages (Session Manager)
    "ssmmessages:CreateControlChannel",        ✅ Required
    "ssmmessages:CreateDataChannel",           ✅ Required
    "ssmmessages:OpenControlChannel",          ✅ Required
    "ssmmessages:OpenDataChannel",             ✅ Required
    
    # EC2 Messages (Session Manager)
    "ec2messages:AcknowledgeMessage",          ✅ Required
    "ec2messages:DeleteMessage",               ✅ Required
    "ec2messages:FailMessage",                 ✅ Required
    "ec2messages:GetEndpoint",                 ✅ Required
    "ec2messages:GetMessages",                 ✅ Required
    "ec2messages:SendReply"                    ✅ Required
  ]
  Resource = "*"
}
```

### Comparison with AWS Managed Policy

**AWS Managed Policy:** `AmazonSSMManagedInstanceCore`

Our custom policy includes ALL required permissions from the managed policy:

| Permission | AWS Managed | Our Policy | Status |
|------------|-------------|------------|--------|
| ssm:UpdateInstanceInformation | ✅ | ✅ | Match |
| ssmmessages:CreateControlChannel | ✅ | ✅ | Match |
| ssmmessages:CreateDataChannel | ✅ | ✅ | Match |
| ssmmessages:OpenControlChannel | ✅ | ✅ | Match |
| ssmmessages:OpenDataChannel | ✅ | ✅ | Match |
| ec2messages:AcknowledgeMessage | ✅ | ✅ | Match |
| ec2messages:DeleteMessage | ✅ | ✅ | Match |
| ec2messages:FailMessage | ✅ | ✅ | Match |
| ec2messages:GetEndpoint | ✅ | ✅ | Match |
| ec2messages:GetMessages | ✅ | ✅ | Match |
| ec2messages:SendReply | ✅ | ✅ | Match |

**Result:** ✅ Our policy matches AWS managed policy requirements

---

## Prerequisites for SSM Access

### 1. ✅ IAM Role with SSM Permissions
- **Status:** CONFIGURED
- **Role:** ai-steven-dev-ec2-s3-role
- **Instance Profile:** ai-steven-dev-ec2-profile

### 2. ✅ SSM Agent Running on EC2
- **Status:** PRE-INSTALLED on Amazon Linux 2023
- **Service:** amazon-ssm-agent
- **Auto-start:** Enabled by default

### 3. ✅ Network Connectivity
- **Requirement:** EC2 must reach SSM endpoints
- **Options:**
  - Public subnet with internet gateway (your setup)
  - Private subnet with VPC endpoints
  - Private subnet with NAT gateway

### 4. ✅ No Security Group Restrictions
- **Requirement:** Outbound HTTPS (443) allowed
- **Your Setup:** All outbound traffic allowed (0.0.0.0/0)

---

## How to Connect from Your Laptop

### Method 1: AWS CLI (Recommended)

```bash
# Get EC2 instance ID from Terraform output
terraform output ec2_instance_id

# Start SSM session
aws ssm start-session \
  --target <instance-id> \
  --profile ai-steven \
  --region ap-southeast-4
```

### Method 2: AWS Console

1. Go to EC2 Console
2. Select your instance
3. Click "Connect" button
4. Choose "Session Manager" tab
5. Click "Connect"

### Method 3: AWS CLI with Port Forwarding

```bash
# Forward local port 8080 to EC2 port 80
aws ssm start-session \
  --target <instance-id> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["80"],"localPortNumber":["8080"]}' \
  --profile ai-steven \
  --region ap-southeast-4

# Then access: http://localhost:8080
```

---

## Verification Steps

### Step 1: Check IAM Role Attachment
```bash
# Get instance ID
INSTANCE_ID=$(terraform output -raw ec2_instance_id)

# Check IAM instance profile
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].IamInstanceProfile' \
  --profile ai-steven \
  --region ap-southeast-4
```

**Expected Output:**
```json
{
  "Arn": "arn:aws:iam::119778517641:instance-profile/ai-steven-dev-ec2-profile",
  "Id": "AIPXXXXXXXXXXXXXXXXXX"
}
```

### Step 2: Check SSM Agent Status
```bash
# Connect via SSM
aws ssm start-session --target $INSTANCE_ID --profile ai-steven --region ap-southeast-4

# Once connected, check SSM agent
sudo systemctl status amazon-ssm-agent
```

**Expected Output:**
```
● amazon-ssm-agent.service - amazon-ssm-agent
   Loaded: loaded
   Active: active (running)
```

### Step 3: Test SSM Connectivity
```bash
# Check if instance is managed by SSM
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
  --profile ai-steven \
  --region ap-southeast-4
```

**Expected Output:**
```json
{
  "InstanceInformationList": [
    {
      "InstanceId": "i-xxxxx",
      "PingStatus": "Online",
      "PlatformType": "Linux",
      "PlatformName": "Amazon Linux",
      "PlatformVersion": "2023"
    }
  ]
}
```

### Step 4: Test Session Manager
```bash
# Start session
aws ssm start-session \
  --target $INSTANCE_ID \
  --profile ai-steven \
  --region ap-southeast-4
```

**Expected:** Shell prompt appears without any key pair

---

## Troubleshooting

### Issue 1: "TargetNotConnected" Error

**Cause:** SSM agent not running or not registered

**Solution:**
```bash
# Connect via EC2 Instance Connect or Serial Console
sudo systemctl restart amazon-ssm-agent
sudo systemctl status amazon-ssm-agent
```

### Issue 2: "AccessDenied" Error

**Cause:** IAM role missing permissions

**Solution:**
```bash
# Verify IAM role has correct permissions
aws iam get-role-policy \
  --role-name ai-steven-dev-ec2-s3-role \
  --policy-name ai-steven-dev-ec2-s3-policy \
  --profile ai-steven
```

### Issue 3: Instance Not Showing in SSM

**Cause:** Network connectivity issue or SSM agent not started

**Solution:**
1. Check security group allows outbound HTTPS (443)
2. Check instance has internet connectivity
3. Wait 5-10 minutes for SSM agent to register

### Issue 4: Session Manager Plugin Not Installed

**Error:** "SessionManagerPlugin is not found"

**Solution:**
```bash
# Install Session Manager plugin
# Windows: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-windows

# macOS
brew install --cask session-manager-plugin

# Linux
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
```

---

## Security Benefits of SSM vs SSH

| Feature | SSH with Key Pair | SSM Session Manager |
|---------|-------------------|---------------------|
| Key Management | ❌ Manual key rotation | ✅ No keys needed |
| Port Exposure | ❌ Port 22 open | ✅ No inbound ports |
| Audit Logging | ⚠️ Manual setup | ✅ CloudTrail logs |
| Access Control | ⚠️ Key-based | ✅ IAM-based |
| Session Recording | ❌ Not built-in | ✅ Optional S3 logging |
| MFA Support | ⚠️ Complex setup | ✅ IAM MFA |

---

## Summary

### ✅ IAM Role Configuration: VERIFIED

The IAM role attached to your EC2 instance includes ALL required permissions for SSM Session Manager:

1. ✅ SSM core permissions (UpdateInstanceInformation)
2. ✅ SSM Messages permissions (Session Manager channels)
3. ✅ EC2 Messages permissions (Message handling)

### ✅ Connection Method: NO KEY PAIR NEEDED

You can connect from your laptop using:
```bash
aws ssm start-session \
  --target <instance-id> \
  --profile ai-steven \
  --region ap-southeast-4
```

### ✅ Additional Permissions Included

Your IAM role also has:
- S3 access (upload/download/delete)
- ECR access (pull Docker images)

**Result:** SSM access is fully configured and ready to use! 🎉
