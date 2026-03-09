@echo off
REM Usage: apply.bat dev   or   apply.bat prod
set ENV=%1
if "%ENV%"=="" set ENV=dev
set TFVARS=envs\%ENV%.tfvars

if not exist "%TFVARS%" (
    echo ERROR: %TFVARS% not found. Usage: apply.bat dev^|prod
    exit /b 1
)

echo ==========================================
echo Environment: %ENV%
echo Var file:    %TFVARS%
echo ==========================================

REM Select or create workspace
terraform workspace select %ENV% 2>nul || terraform workspace new %ENV%

REM Import shared S3 bucket if not in state
echo Importing S3 bucket if exists...
terraform import -var-file="%TFVARS%" module.s3.aws_s3_bucket.main ai-foundry-artifacts-apse4 2>nul

echo.
echo Running terraform apply...
terraform apply -var-file="%TFVARS%" %2 %3 %4 %5
