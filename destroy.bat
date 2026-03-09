@echo off
REM Usage: destroy.bat dev   or   destroy.bat prod
set ENV=%1
if "%ENV%"=="" set ENV=dev
set TFVARS=envs\%ENV%.tfvars

if not exist "%TFVARS%" (
    echo ERROR: %TFVARS% not found. Usage: destroy.bat dev^|prod
    exit /b 1
)

echo ==========================================
echo Environment: %ENV%
echo Var file:    %TFVARS%
echo ==========================================

REM Select workspace
terraform workspace select %ENV% 2>nul
if errorlevel 1 (
    echo ERROR: Workspace '%ENV%' not found
    exit /b 1
)

echo Removing S3 from state and destroying other resources...
terraform state rm module.s3.aws_s3_bucket.main 2>nul
terraform state rm module.s3.aws_s3_bucket_public_access_block.main 2>nul
terraform state rm module.s3.aws_s3_bucket_versioning.main 2>nul
terraform state rm module.s3.aws_s3_bucket_server_side_encryption_configuration.main 2>nul
terraform state rm module.s3.aws_s3_object.init_script 2>nul
terraform state rm module.s3.null_resource.destroy_warning 2>nul

terraform destroy -var-file="%TFVARS%" %2 %3 %4 %5
