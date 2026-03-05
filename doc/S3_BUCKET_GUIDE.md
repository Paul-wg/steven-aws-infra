# S3 Bucket Handling - Quick Reference

## Bucket Name: ai-foundry-artifacts-apse4

### Pre-Apply Check (Recommended)
```bash
check_bucket.bat ai-foundry-artifacts-apse4 ai-steven
```

### Scenario 1: Bucket Doesn't Exist
**What happens:**
- Terraform creates the bucket
- Applies versioning, encryption, and access controls

**Action:** Just run `terraform apply`

### Scenario 2: Bucket Exists in Your Account
**What happens:**
- Terraform detects existing bucket
- Shows error: "bucket already exists"

**Action:** Import the bucket first
```bash
terraform import module.s3.aws_s3_bucket.main ai-foundry-artifacts-apse4
terraform apply
```

**Result:** Terraform manages existing bucket without recreating it

### Scenario 3: Bucket Exists in Another Account
**What happens:**
- Terraform shows error: "bucket name already taken"
- Cannot proceed

**Action:** Change bucket name in terraform.tfvars
```
s3_bucket_name = "ai-foundry-artifacts-apse4-alternative"
```

## Destroy Protection

### When Running `terraform destroy`
**What happens:**
1. Terraform will show warning message
2. S3 bucket will NOT be deleted (protected by lifecycle rule)
3. Other resources (EC2, IAM roles) will be destroyed
4. Destroy operation completes successfully

**Message shown:**
```
WARNING: S3 bucket 'ai-foundry-artifacts-apse4' is protected and kept
The bucket and its contents are preserved for data safety
```

### To Actually Delete the Bucket
1. Edit `modules/s3/main.tf`
2. Remove or comment out:
   ```hcl
   lifecycle {
     prevent_destroy = true
   }
   ```
3. Run `terraform destroy` again

## Permissions

### Administrators
- Full access via AWS account permissions
- Can upload/download via AWS Console or CLI

### EC2 Instance
- Automatic access via IAM instance profile
- Can upload/download/delete files
- Use AWS CLI or SDK from EC2:
  ```bash
  aws s3 cp file.txt s3://ai-foundry-artifacts-apse4/
  aws s3 ls s3://ai-foundry-artifacts-apse4/
  ```
