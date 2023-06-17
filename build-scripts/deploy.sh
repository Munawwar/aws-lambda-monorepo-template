#!/bin/sh

# Linux dependencies: jq
# One debian servers you need to `apt -qq install -y jq`
#
# Usage:
# ENV=prod REGION=us-east-1 build-scripts/deploy.sh lambda-servica-a

RED='\x1B[1;31m'
DEFCOLOR='\x1B[0;m'

if [ -z "${ENV}" ]; then
  printf $RED'ENV environment variable should be set. e.g. prod or dev'$DEFCOLOR'\n'
  exit 1
fi
if [ -z "${REGION}" ]; then
  printf $RED'REGION environment variable should be set. e.g. eu-west-1'$DEFCOLOR'\n'
  exit 1
fi
if [ -z "$1" ]; then
  printf $RED'Specify which lambda package to deploy'$DEFCOLOR'\n'
  exit 1
fi

# Find and delete unrelated apps/libs
echo '--- Find and delete unrelated apps/libs ---'
# Install nx first to that
cp package.json package-original.json
jq 'del(.workspaces)' package.json > package-temp.json
mv package-temp.json package.json
npm ci --omit=dev
cp package-original.json package.json

npm run ci:graph
echo "$1" > temp.txt
cat graph.json | jq -r ".graph.dependencies[\"$1\"][].target" >> temp.txt
cat temp.txt | sort > needed.txt
ls packages/ | sort > all.txt
comm -23 all.txt needed.txt > diff.txt
cat diff.txt |
  sed 's/^/.\/packages\//' |
  xargs -I %1 rm -r %1
rm graph.json temp.txt needed.txt all.txt diff.txt
echo '---\n'

# Install prod dependecies of root and affected packages
echo '--- Install prod dependencies ---'
# Remove nx from the dependencies so that it doesn't bloat the node_modules folder
jq 'del(.dependencies.nx)' package.json > package-temp.json
mv package-temp.json package.json
npm ci --omit=dev
cp package-original.json package.json
echo '---\n'

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

# Remove files that dont need to be in lambda zip file
rm -rf *.md
rm -rf packages/lib-*/*.md
rm -rf packages/lambda-*/*.md
rm -rf .gitignore .prettierrc .prettierignore .tsconfig nx.json LICENSE package-original.json package-lock.json packages/.gitkeep
rm -rf packages/lib-*/.gitignore
rm -rf packages/lambda-*/.gitignore
rm -rf packages/lib-*/.package-lock.json
rm -rf packages/lambda-*/.package-lock.json
rm -rf tests
rm -rf packages/lib-*/tests
rm -rf packages/lambda-*/tests
rm -rf types
rm -rf packages/lib-*/types
rm -rf packages/lib-*/tsconfig.json
rm -rf packages/lambda-*/types
rm -rf packages/lambda-*/tsconfig.json

# Create symlink index.js pointing to the lambda's index.js for default lambda handler entry
# This line isn't needed if you point each of your lambda correctly to packages/<name>/index.handler
ln -s packages/$1/index.js index.js

# keep node_module symlinks in zip file
zip --symlinks -qr --exclude=.git/* --exclude=build-scripts/* $ZIP_FILE .
rm index.js

# Start lambda zip file upload
aws --region ${REGION} s3 cp ${ZIP_FILE} ${S3_URI}
aws --region ${REGION} lambda update-function-code --function-name ${FUNCTION_NAME} --s3-bucket ${S3_BUCKET} --s3-key ${PREFIX}/${ZIP_FILE}
aws --region ${REGION} s3 rm ${S3_URI}
rm ${ZIP_FILE}
