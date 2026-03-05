@echo off
REM S3 Bucket Pre-check Script
REM This script checks if the S3 bucket exists and who owns it

set BUCKET_NAME=%1
set AWS_PROFILE=%2

if "%BUCKET_NAME%"=="" (
    echo Usage: check_bucket.bat BUCKET_NAME AWS_PROFILE
    exit /b 1
)

if "%AWS_PROFILE%"=="" (
    set AWS_PROFILE=default
)

echo Checking S3 bucket: %BUCKET_NAME%
echo Using AWS profile: %AWS_PROFILE%
echo.

aws s3api head-bucket --bucket %BUCKET_NAME% --profile %AWS_PROFILE% 2>nul

if %ERRORLEVEL% EQU 0 (
    echo INFO: S3 bucket '%BUCKET_NAME%' exists and is accessible in your AWS account.
    echo Terraform will use the existing bucket.
    exit /b 0
) else (
    aws s3 ls s3://%BUCKET_NAME% --profile %AWS_PROFILE% 2>nul
    if %ERRORLEVEL% EQU 255 (
        echo ERROR: S3 bucket '%BUCKET_NAME%' exists but is owned by another AWS account.
        echo Please choose a different bucket name.
        exit /b 1
    ) else (
        echo INFO: S3 bucket '%BUCKET_NAME%' does not exist. Terraform will create it.
        exit /b 0
    )
)
