#!/bin/sh
# install prod dependencies of project root only (this is for the nx binray)
cp package.json package-orignal.json
jq 'del(.workspaces)' package.json > package2.json
mv package2.json package.json
npm ci --omit=dev
mv package-orignal.json package.json

# Delete non-affected apps
ls packages/ | grep -E '^(lambda|ecs)-' | sort > all.txt
node_modules/.bin/nx print-affected --base=main --head=HEAD --select=projects | awk -F', ' '{ for( i=1; i<=NF; i++ ) print $i }' | grep -E '^lambda-' | sort > affected.txt 
comm -23 all.txt affected.txt | sed 's/^/.\/packages\//' | tr '\n' ' ' > non-affected.txt
echo '\n--- Affected Lambdas ---'
cat affected.txt
echo '\n--- Not Affected ---'
cat non-affected.txt
rm all.txt affected.txt non-affected.txt
echo '\n'
