#!/bin/sh
# Usage:
# ENV=prod REGION=us-east-1 deploy.sh lambda-servica-a

RED='\x1B[1;31m'
DEFCOLOR='\x1B[0;m'

if [ -z "${ENV}" ]; then
  printf $RED'ENV environment variable should be set. e.g. prod or dev'$DEFCOLOR
  exit 1
fi
if [ -z "${REGION}" ]; then
  printf $RED'REGION environment variable should be set. e.g. eu-west-1'$DEFCOLOR
  exit 1
fi

# Install prod dependecies of root and affected packages
yarn install --prod --pure-lockfile

# Build them
PREFIX=$(echo $1 | sed "s/^lambda-//")
# Assuming your lambda function name is just the package-name without the "lambda-"
FUNCTION_NAME=PREFIX
S3_URI=s3://${ENV}-builds/${PREFIX}/
BUILD_NUMBER=$(date +"%Y-%m-%d-%H%M")
ZIP_FILE=${PREFIX}-${BUILD_NUMBER}.zip

echo '\n--- Package and upload ---'
echo 'ENV='$ENV
echo 'S3_URI='$S3_URI
echo 'ZIP_FILE='$ZIP_FILE

cd packages/$1
zip -qr --exclude=README.md* --exclude=yarn.lock --exclude=.eslintignore --exclude=tests/* --exclude=types/* ${ZIP_FILE} .
aws --region ${REGION} s3 cp ${ZIP_FILE} ${S3_URI}
aws --region ${REGION} lambda update-function-code --function-name ${FUNCTION_NAME} --s3-bucket ${S3_BUCKET} --s3-key ${PREFIX}/${ZIP_FILE}
aws --region ${REGION} s3 rm ${S3_URI}
rm ${ZIP_FILE}
