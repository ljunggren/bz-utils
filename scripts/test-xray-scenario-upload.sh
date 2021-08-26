#/bin/bash

# This scripts test integration with Xray and assumes you have defined the following scenario in Jira
# https://raw.githubusercontent.com/ljunggren/bz-utils/main/test/cucumber-sample-scenario.txt

# Make sure you export your client id and client secret as environment variables
# export CLIENT_ID=my-secret-id
# export CLIENT_SECRET=my-secret-secret

# Get report sample file from GitHub
curl https://raw.githubusercontent.com/ljunggren/bz-utils/main/test/cucumber-sample-report.json --output results.json

echo Checking: ${CLIENT_ID} ${CLIENT_SECRET}
echo Checking: curl -H "Content-Type: application/json" -X POST --data '{ "client_id": "'${CLIENT_ID}'","client_secret": "'${CLIENT_SECRET}'"}' 

TOKEN=$(curl -H "Content-Type: application/json" -X POST --data '{ "client_id": "'${CLIENT_ID}'","client_secret": "'${CLIENT_SECRET}'"}'  https://xray.cloud.xpand-it.com/api/v1/authenticate | sed 's/\"//g')

echo $TOKEN

curl -H "Content-Type: application/json" -X POST -H "Authorization: Bearer ${TOKEN}" --data @results.json https://xray.cloud.xpand-it.com/api/v2/import/execution/cucumber
