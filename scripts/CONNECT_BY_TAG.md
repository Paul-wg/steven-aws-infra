# Connect to EC2 via Tag Name

## EC2 Instance Tag

The EC2 instance is tagged with:
```
name = "Nebulas-host"
```

This allows you to connect to the instance even after it's recreated, without needing to look up the instance ID.

---

## Connection Scripts

### Windows: `scripts/connect-ai-host.bat`

**Usage:**
```cmd
cd aws-infra
scripts\connect-ai-host.bat
```

**What it does:**
1. Looks up instance ID using tag `name=Nebulas-host`
2. Verifies instance is running
3. Connects via SSM Session Manager

### Linux/macOS: `scripts/connect-ai-host.sh`

**Usage:**
```bash
cd aws-infra
chmod +x scripts/connect-ai-host.sh
./scripts/connect-ai-host.sh
```

---

## Manual Connection Using Tag

### Get Instance ID by Tag
```bash
# Windows
aws ec2 describe-instances ^
  --filters "Name=tag:name,Values=Nebulas-host" "Name=instance-state-name,Values=running" ^
  --query "Reservations[0].Instances[0].InstanceId" ^
  --output text ^
  --profile ai-steven ^
  --region ap-southeast-4

# Linux/macOS
aws ec2 describe-instances \
  --filters "Name=tag:name,Values=Nebulas-host" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text \
  --profile ai-steven \
  --region ap-southeast-4
```

### Connect Using Instance ID
```bash
aws ssm start-session \
  --target <instance-id> \
  --profile ai-steven \
  --region ap-southeast-4
```

---

## One-Liner Connection

### Windows (PowerShell)
```powershell
$id = aws ec2 describe-instances --filters "Name=tag:name,Values=Nebulas-host" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text --profile ai-steven --region ap-southeast-4; aws ssm start-session --target $id --profile ai-steven --region ap-southeast-4
```

### Linux/macOS (Bash)
```bash
aws ssm start-session \
  --target $(aws ec2 describe-instances \
    --filters "Name=tag:name,Values=Nebulas-host" "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text \
    --profile ai-steven \
    --region ap-southeast-4) \
  --profile ai-steven \
  --region ap-southeast-4
```

---

## Benefits of Using Tag-Based Connection

### ✅ Persistent Identifier
- Instance ID changes when EC2 is recreated
- Tag `name=Nebulas-host` remains constant
- Scripts work after `terraform destroy` + `terraform apply`

### ✅ Multiple Environments
You can have multiple instances with different tags:
```
name=Nebulas-host-dev
name=Nebulas-host-staging
name=Nebulas-host-prod
```

### ✅ Automation Friendly
- CI/CD pipelines can use tag to find instance
- No need to update scripts with new instance IDs
- Works with auto-scaling groups

---

## Troubleshooting

### Error: "No running instance found"

**Possible causes:**
1. Instance is not running (stopped/terminated)
2. Tag doesn't exist or has wrong value
3. Wrong AWS profile or region

**Check instance status:**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:name,Values=Nebulas-host" \
  --query "Reservations[0].Instances[0].[InstanceId,State.Name,Tags]" \
  --profile ai-steven \
  --region ap-southeast-4
```

### Error: "SessionManagerPlugin is not found"

**Solution:** Install AWS Session Manager plugin
- Windows: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-windows
- macOS: `brew install --cask session-manager-plugin`
- Linux: Download from AWS documentation

---

## Example Session

```bash
$ ./scripts/connect-ai-host.sh
==========================================
Connecting to EC2 with tag name=Nebulas-host
==========================================

Looking up instance ID...
Found instance: i-0123456789abcdef0

Starting SSM session...
==========================================

Starting session with SessionId: user-0123456789abcdef0
sh-5.2$ whoami
ec2-user
sh-5.2$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
sh-5.2$ exit
```

---

## GitHub Actions Integration

Use the tag in your CI/CD pipeline:

```yaml
- name: Get EC2 Instance ID
  run: |
    INSTANCE_ID=$(aws ec2 describe-instances \
      --filters "Name=tag:name,Values=Nebulas-host" "Name=instance-state-name,Values=running" \
      --query "Reservations[0].Instances[0].InstanceId" \
      --output text \
      --region ap-southeast-4)
    echo "INSTANCE_ID=$INSTANCE_ID" >> $GITHUB_ENV

- name: Deploy to EC2
  run: |
    aws ssm send-command \
      --instance-ids ${{ env.INSTANCE_ID }} \
      --document-name "AWS-RunShellScript" \
      --parameters 'commands=[...]' \
      --region ap-southeast-4
```

---

## Summary

✅ **Tag Added:** `name=Nebulas-host`  
✅ **Windows Script:** `connect-ai-host.bat`  
✅ **Linux/macOS Script:** `connect-ai-host.sh`  
✅ **Works After Recreate:** Instance ID changes, tag stays the same  
✅ **Automation Ready:** Use in CI/CD pipelines  

**Quick Connect:**
```bash
# Windows
scripts\connect-ai-host.bat

# Linux/macOS
./scripts/connect-ai-host.sh
```
