#!/usr/bin/env bash

FILE_PATTERN=report*.json

if [[ -z "$(ls -1 $FILE_PATTERN 2>/dev/null)" ]] ; then
    echo No report files exists. Exiting...
    exit
fi

total="$(ls $FILE_PATTERN |wc -l)"
failed="$(grep failed $FILE_PATTERN |wc -l)"
skipped="$(grep skipped $FILE_PATTERN | wc -l)"
pending="$(grep pending $FILE_PATTERN |wc -l)"

printf "\n"
echo "### TEST SCENARIO SUMMARY ###"
printf "\n"

#echo "Total: $total,  Failed: $failed,  Skipped: $skipped,  Pending: $pending"
printf "Total: %s\nFailed: %s\nSkipped: %s\nPending: %s\n" $total $failed $skipped $pending
printf "\n"

printf "\n"
echo "### ROOT CASUE ANALYSIS ###"
printf "\n"

total_issues="$(grep -ho "\[Error Hash: .*\]" $FILE_PATTERN |sort |uniq -c|wc -l)"
top_issues="$(grep -ho "\[Error Hash: .*\]" $FILE_PATTERN |sort |uniq -c)"

tbd_issues=0
application_issues=0
automation_issues=0
unknown_issues=0

#printf "Total issues: %s\nTo be defined: %s\nApplication: %s\nAutomation: %s\nUnknow: %s\n" $total $tbd_issues $application_issues $automation_issues $unknown_issues
#printf "\n"

echo "Total issues: $total_issues"
echo "Most impactful issues"
echo "$top_issues"

printf "\n"
echo "### SLOWEST TEST STEPS ###"
printf "\n"

slow_steps="$(cat report_cucumber-*.json | jq -c '.[] |.elements' | jq -c '.[] |.steps'[] | jq '"\(.result.duration)_\(.name)|"' |sort -Vr | head -10 |sed 's/^.//;s/.$//')"

times="$(cat report_cucumber-*.json | jq -c '.[] |.elements' | jq -c '.[] |.steps'[]| jq '"\(.result.duration) \(.name)"' |sort -Vr | head -10 | sed 's/^.//;s/.$//' | awk '{system("date -d@"$1/1000000000" -u +%H:%M:%S")}')"

echo $slow_steps|sed 's/_/: /g' |sed 's/|/\n/g'|sed -e 's/^[ \t]*//'

#printf "\n"
echo "Times in hh:mm:ss: " $times


worker_list="$(ls -rt $FILE_PATTERN | xargs grep -ho "\[m.*t.*\].*" | sed 's/..$//')"
printf "\n"
echo "### JOB/WORKER LIST SORTED BY TIME OF COMPLETION ###"
printf "\n"
echo "$worker_list"

printf "\n"
printf "\n"


