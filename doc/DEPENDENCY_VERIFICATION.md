# EC2 to S3 Dependency Verification

## Dependency Chain

```
S3 Module
  ├─> S3 Bucket Created
  ├─> Public Access Block Applied
  ├─> Versioning Enabled
  ├─> Encryption Configured
  ├─> IAM Role Created
  ├─> IAM Instance Profile Created
  └─> Init Script Uploaded
      │
      └─> bucket_ready output (depends on all S3 resources)
      └─> init_script_uploaded output
          │
          ▼
EC2 Module (depends_on S3 outputs)
  ├─> Security Group Created
  └─> EC2 Instance Created
      │
      └─> Uses s3_bucket_id variable (implicit dependency)
      └─> User data references S3 bucket
          │
          ▼
EIP Module (depends_on EC2)
  └─> Elastic IP Associated
```

## Dependency Mechanisms

### 1. Explicit Module Dependency
```hcl
module "ec2" {
  ...
  depends_on = [
    module.s3.bucket_ready,
    module.s3.init_script_uploaded
  ]
}
```

### 2. Output Dependencies
```hcl
# S3 Module outputs.tf
output "bucket_ready" {
  value      = aws_s3_bucket.main.id
  depends_on = [
    aws_s3_bucket.main,
    aws_s3_bucket_public_access_block.main,
    aws_s3_bucket_versioning.main,
    aws_s3_bucket_server_side_encryption_configuration.main
  ]
}

output "init_script_uploaded" {
  value = aws_s3_object.init_script.id
}
```

### 3. Variable Reference Dependency
```hcl
# EC2 Module receives S3 bucket ID
variable "s3_bucket_id" {
  description = "S3 bucket ID to ensure bucket exists"
  type        = string
}

# Used in user_data (creates implicit dependency)
user_data = <<-EOF
  # Verify S3 bucket exists: ${var.s3_bucket_id}
  aws s3 cp s3://${var.s3_bucket_name}/...
EOF
```

### 4. IAM Instance Profile Dependency
```hcl
# EC2 uses IAM instance profile from S3 module
iam_instance_profile = module.s3.ec2_instance_profile_name
```

## Terraform Execution Order

1. **S3 Bucket** - Created first
2. **S3 Bucket Configuration** - Public access block, versioning, encryption
3. **IAM Role & Profile** - Created for EC2
4. **Init Script Upload** - Uploaded to S3
5. **S3 Outputs** - bucket_ready and init_script_uploaded computed
6. **EC2 Security Group** - Created
7. **EC2 Instance** - Created ONLY after S3 is ready
8. **Elastic IP** - Associated ONLY after EC2 is ready

## What Happens if S3 Doesn't Exist?

### Scenario 1: S3 Bucket Creation Fails
```
❌ S3 bucket creation fails
   └─> bucket_ready output cannot be computed
       └─> EC2 module depends_on fails
           └─> EC2 instance NOT created
```

### Scenario 2: Init Script Upload Fails
```
❌ Init script upload fails
   └─> init_script_uploaded output cannot be computed
       └─> EC2 module depends_on fails
           └─> EC2 instance NOT created
```

### Scenario 3: IAM Role Creation Fails
```
❌ IAM role creation fails
   └─> ec2_instance_profile_name output cannot be computed
       └─> EC2 module variable iam_instance_profile has no value
           └─> EC2 instance NOT created
```

## Testing the Dependency

### Test 1: Normal Flow
```bash
terraform apply
```
**Expected:**
1. S3 bucket created
2. Init script uploaded
3. EC2 instance created
4. EIP associated

### Test 2: S3 Bucket Already Exists
```bash
# Import existing bucket
terraform import module.s3.aws_s3_bucket.main ai-foundry-artifacts-apse4
terraform apply
```
**Expected:**
1. S3 bucket imported (exists)
2. Init script uploaded
3. EC2 instance created
4. EIP associated

### Test 3: Force S3 Failure (Simulation)
```bash
# Comment out S3 bucket resource temporarily
# terraform apply will fail
```
**Expected:**
1. S3 bucket creation fails
2. EC2 instance NOT created
3. EIP NOT created

## Verification Commands

### Check Terraform Plan Order
```bash
terraform plan
# Look for creation order in the plan output
```

### Check Terraform Graph
```bash
terraform graph | dot -Tpng > graph.png
# Visual representation of dependencies
```

### Check State After Apply
```bash
terraform state list
# Should show S3 resources before EC2 resources
```

## Summary

✅ **Multiple dependency mechanisms ensure EC2 will NOT be created if S3 doesn't exist:**

1. ✅ Explicit `depends_on` in main.tf
2. ✅ Output dependencies in S3 module
3. ✅ Variable reference (s3_bucket_id) in EC2 module
4. ✅ IAM instance profile dependency
5. ✅ User data references S3 bucket

**Result:** EC2 creation is blocked until S3 bucket is fully ready and init script is uploaded.
