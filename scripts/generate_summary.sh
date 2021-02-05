#!/usr/bin/env bash

FILE_PATTERN="$@"

if [[ -z "$(ls -1 $FILE_PATTERN 2>/dev/null)" ]] ; then
    echo No report files exists. Exiting...
    exit
fi

if ! command -v jq &> /dev/null
then
    echo "JSON parser jq could not be found"
    echo "Please install it!"
    exit
fi

total_scenarios="$(grep Scenario $FILE_PATTERN | wc -l)"
failed_scenarios="$(grep failed $FILE_PATTERN | wc -l)"

printf "\n"
printf "#############################\n"
printf "### TEST SCENARIO SUMMARY ###\n"
printf "#############################\n"
printf "\n"

if [ -z "$total_scenarios" ]
then
    printf "No scenarios found\n"
else
   printf "Total: %s\nFailed: %s\n" $total_scenarios $failed_scenarios
fi

total="$(grep status $FILE_PATTERN | wc -l)"
failed="$(grep failed $FILE_PATTERN | wc -l)"
skipped="$(grep skipped $FILE_PATTERN | wc -l)"
pending="$(grep pending $FILE_PATTERN |wc -l)"

printf "\n"
printf "#########################\n"
printf "### TEST STEP SUMMARY ###\n"
printf "#########################\n"
printf "\n"

if [ -z "$total" ]
then
    printf "No test steps found\n"
else
    printf "Total: %s\nFailed: %s\nSkipped: %s\nPending: %s\n" $total $failed $skipped $pending
fi

all_issues="$(cat $FILE_PATTERN | jq -c '.[] |.elements'[0].extraData |jq -c 'select(.rootCase != null)' |jq -c '"\(.rootCase.errHash)#\(.rootCase.desc)#\(.rootCase.type)#\(.rootCase.scope)#\(.id) "' | sed 's/^.//;s/.$//')"
unique_issues="$(cat $FILE_PATTERN | jq -c '.[] |.elements'[0].extraData |jq -c 'select(.rootCase != null)' |jq -c '"\(.rootCase.errHash)#\(.rootCase.desc)#\(.rootCase.type)#\(.rootCase.scope)"' | sed 's/^.//;s/.$//'| sort | uniq -c | sort -r)"

total_issues="$(echo "$unique_issues" | grep "#" | wc -l)"
tbd_issues="$(echo "$unique_issues" | grep null | wc -l)"
application_issues="$(echo "$unique_issues" | grep app | wc -l)"
automation_issues="$(echo "$unique_issues" | grep auto | wc -l)"
unknown_issues="$(echo "$unique_issues" | grep unknow | wc -l)"

printf "\n"
printf "###########################\n"
printf "### ROOT CAUSE ANALYSIS ###\n"
printf "###########################\n"
printf "\n"

if [ -z "$unique_issues" ]
then
    printf "No issues found\n"
else
    printf "Total issues: %s\nTo be defined: %s\nApplication: %s\nAutomation: %s\nUnknown: %s\n" $total_issues $tbd_issues $application_issues $automation_issues $unknown_issues
    printf "\n"
    printf "Most impactful issues\n"
    printf "\n"
    echo "${unique_issues}"|sed 's/#/ /g' 
fi

slow_steps="$(cat $FILE_PATTERN | jq -c '.[] |.elements' | jq -c '.[] |.steps'[] | jq '"\(.result.duration)_\(.name)|"' |sort -Vr | head -10 |sed 's/^.//;s/.$//')" 
#times="$(cat $FILE_PATTERN | jq -c '.[] |.elements' | jq -c '.[] |.steps'[]| jq '"\(.result.duration) \(.name)"' |sort -Vr | head -10 | sed 's/^.//;s/.$//' | awk '{system("date -d@"$1/1000000000" -u +%H:%M:%S")}')"
printf "\n"
printf "##########################\n"
printf "### SLOWEST TEST STEPS ###\n"
printf "##########################\n"
printf "\n"

if [ -z "$slow_steps" ]
then
    printf "No test steps found\n"
else
    echo $slow_steps|sed 's/_/: /g' |sed 's/|/\n/g'|sed -e 's/^[ \t]*//'
fi

worker_list="$(ls -rt $FILE_PATTERN | xargs grep -ho "\[m.*t.*\].*" | sed 's/..$//')"

printf "\n"
printf "####################################################\n"
printf "### JOB/WORKER LIST SORTED BY TIME OF COMPLETION ###\n"
printf "####################################################\n"
printf "\n"

if [ -z "$worker_list" ]
then
    printf "No jobs found\n"
else
    echo "$worker_list"
fi

printf "\n"
printf "### END REPORT ####\n"



