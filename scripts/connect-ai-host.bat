@echo off
REM Connect to EC2 via SSM using tag name=Nebulas-host

set AWS_PROFILE=ai-steven
set AWS_REGION=ap-southeast-4
set TAG_NAME=Nebulas-host

echo ==========================================
echo Connecting to EC2 with tag name=%TAG_NAME%
echo ==========================================
echo.

REM Get instance ID by tag
echo Looking up instance ID...
for /f "tokens=*" %%i in ('aws ec2 describe-instances --filters "Name=tag:name,Values=%TAG_NAME%" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text --profile %AWS_PROFILE% --region %AWS_REGION%') do set INSTANCE_ID=%%i

if "%INSTANCE_ID%"=="None" (
    echo ERROR: No running instance found with tag name=%TAG_NAME%
    echo.
    echo Please check:
    echo 1. Instance is running
    echo 2. Tag name=Nebulas-host exists
    echo 3. AWS profile and region are correct
    exit /b 1
)

echo Found instance: %INSTANCE_ID%
echo.
echo Starting SSM session...
echo ==========================================
echo.

aws ssm start-session --target %INSTANCE_ID% --profile %AWS_PROFILE% --region %AWS_REGION%
