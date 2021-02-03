#!/usr/bin/env bash

FILE_PATTERN=report*.json

total="$(ls $FILE_PATTERN |wc -l)"
failed="$(grep failed $FILE_PATTERN |wc -l)"
skipped="$(grep skipped $FILE_PATTERN | wc -l)"
pending="$(grep pending $FILE_PATTERN |wc -l)"

echo "### OVERALL TEST SUMMARY ###"
echo "Total: $total,  Failed: $failed,  Skipped: $skipped,  Pending: $pending"
printf "\n"

echo "### ROOT CASUE ANALYSIS ###"

total_issues="$(grep -ho "\[Error Hash: .*\]" $FILE_PATTERN |sort |uniq -c|wc -l)"
top_issues="$(grep -ho "\[Error Hash: .*\]" $FILE_PATTERN |sort |uniq -c)"



tbd_issues=0
application_issues=0
automation_issues=0
unknown_issues=0

echo "Total issues: $total_issues"
echo "Most impactful issues"
echo "$top_issues"

printf "\n"

echo "To be defined: $tbd_issues,  Application issues: $application_issues,  Automation issues: $automation_issues,  Unknown issues: $unknown_issues" 

printf "\n"

worker_list="$(ls -rt $FILE_PATTERN | xargs grep -ho "\[m.*t.*\].*" | sed 's/..$//')"

echo "### JOB/WORKER LIST SORTED BY TIME OF COMPLETION ###"
echo "$worker_list"

