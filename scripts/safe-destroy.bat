@echo off
REM Usage: safe-destroy.bat dev   or   safe-destroy.bat prod

set ENV=%1
if "%ENV%"=="" set ENV=dev
set TFVARS=envs\%ENV%.tfvars

if not exist "%TFVARS%" (
    set TFVARS=..\envs\%ENV%.tfvars
)

if not exist "%TFVARS%" (
    echo ERROR: envs\%ENV%.tfvars not found. Usage: safe-destroy.bat dev^|prod
    exit /b 1
)

echo ==========================================
echo Safe Terraform Destroy — Environment: %ENV%
echo ==========================================
echo This will:
echo 1. Remove S3 bucket from Terraform state
echo 2. Destroy all other resources (RDS Aurora, EC2, EIP, IAM, VPC endpoints/SGs)
echo    NOTE: Private DB subnets are NOT managed by Terraform — will NOT be destroyed
echo 3. Keep S3 bucket intact in AWS
echo ==========================================
echo.

set /p confirm="Continue? (yes/no): "
if not "%confirm%"=="yes" (
    echo Aborted.
    exit /b 0
)

REM Select workspace
terraform workspace select %ENV% 2>nul
if errorlevel 1 (
    echo ERROR: Workspace '%ENV%' not found
    exit /b 1
)

echo.
echo Step 1: Removing S3 resources from Terraform state...
terraform state rm module.s3.aws_s3_bucket.main 2>nul || echo   - S3 bucket already removed or doesn't exist
terraform state rm module.s3.aws_s3_bucket_public_access_block.main 2>nul || echo   - Public access block already removed
terraform state rm module.s3.aws_s3_bucket_versioning.main 2>nul || echo   - Versioning already removed
terraform state rm module.s3.aws_s3_bucket_server_side_encryption_configuration.main 2>nul || echo   - Encryption config already removed
terraform state rm module.s3.aws_s3_object.init_script 2>nul || echo   - Init script already removed
terraform state rm module.s3.null_resource.destroy_warning 2>nul || echo   - Destroy warning already removed

echo.
echo Step 2: Destroying remaining resources...
terraform destroy -var-file="%TFVARS%"

echo.
echo ==========================================
echo Destroy complete!
echo S3 bucket 'ai-foundry-artifacts-apse4' is preserved in AWS
echo ==========================================
