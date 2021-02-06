#!/usr/bin/env bash

FILE_PATTERN="$@"

if [ $# -lt 1 ]; then
    printf "\n"
    echo Usage: ./generate_summary.sh *.json
    printf "\n"
    exit
fi

if [[ -z "$(ls -1 $FILE_PATTERN 2>/dev/null)" ]] ; then
    printf "\n"
    echo No report files exists. Exiting...
    printf "\n"
    exit
fi

if ! command -v jq &> /dev/null
then
    printf "\n"
    echo "JSON parser jq could not be found"
    echo "Please install it!"
    printf "\n"
    exit
fi

total_scenarios="$(grep Scenario $FILE_PATTERN | wc -l)"
failed_scenarios="$(grep status $FILE_PATTERN | grep failed | wc -l)"

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
failed="$(grep status $FILE_PATTERN | grep failed | wc -l)"
skipped="$(grep status $FILE_PATTERN | grep skipped | wc -l)"
pending="$(grep status $FILE_PATTERN | grep pending | wc -l)"

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
unique_issues="$(cat $FILE_PATTERN | jq -c '.[] |.elements'[0].extraData |jq -c 'select(.rootCase != null)' |jq -c '"\(.rootCase.errHash)_\(.rootCase.desc)_\(.rootCase.type)_\(.rootCase.scope)"' | sed 's/^.//;s/.$//'| sort | uniq -c | sort -r)"

total_issues="$(echo "$unique_issues" | grep "_" | wc -l)"
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
    echo "${unique_issues}"|sed 's/_/ /g' 
fi

slow_steps="$(cat $FILE_PATTERN | jq -c '.[] |.elements' | jq -c '.[] |.steps'[] | jq '"\(.result.duration/1000000)ms_\(.name)|"' |sort -Vr | head -10 |sed 's/^.//;s/.$//')" 
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
    echo $slow_steps|sed 's/_/ /g' |sed 's/|/\n/g'|sed -e 's/^[ \t]*//'
    printf "\n"
fi

worker_list="$(ls -rt $FILE_PATTERN | xargs grep -ho "\[m.*t.*\].*" |  sed 's/..$//')"

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

if [[ -z "$(ls -1 bz-report-template.html 2>/dev/null)" ]] ; then
    printf "\n"
    echo No html template found. Exiting...
    printf "\n"
    exit
fi

printf "\n"
printf "####################################################\n"
printf "### GENERATING HTML REPORT ###\n"
printf "####################################################\n"
printf "\n"

now=$(date +"%Y-%m-%d")

file=$(echo bz-report-$now.html)
printf "%s\n" Generating file: $file

#cat bz-report-template.html > $file
cat > $file <<'EOF'
  <html>
  <head>
    <title>Boozang report</title>
  </head>
  <body>
    <h1>Boozang report</h1>
EOF

 printf "<h3>%s</h3>" "Scenarios" >> $file
 printf "<ul><li>Total: %s</li><li>Failed: %s</li></ul>" $total_scenarios $failed_scenarios >> $file

 printf "<h3>%s</h3>" "Test Steps" >> $file
 printf "<ul><li>Total: %s</li><li>Failed: %s</li><li>Skipped: %s</li><li>Pending: %s</li></ul>" $total $failed $skipped $pending  >> $file

printf "<h3>%s</h3>" "Issues" >> $file
if [ -z "$unique_issues" ]
then
    printf "No issues found\n"  >> $file
else
    printf "<ul><li>Total issues: %s</li><li>To be defined: %s</li><li>Application: %s</li><li>Automation: %s</li><li>Unknown: %s</li></ul>" $total_issues $tbd_issues $application_issues $automation_issues $unknown_issues  >> $file
    printf "\n"  >> $file
    printf "<h3>Most impactful issues</h3>"  >> $file
    printf "\n"  >> $file
    printf "<table>" >>  $file;
    while IFS= read -r line ; do 
      echo "<tr><td>" >> $file;
      echo $line | sed 's~_~</td><td>~g' |sed 's/|/\n/g'|sed 's/null/-/g'   >> $file;
      echo "</td></tr>"  >> $file;
    done <<< "$unique_issues"
    printf "</table>" >>  $file;
fi

printf "<h3>%s</h3>" "Issues" >> $file
if [ -z "$slow_steps" ]
then
    printf "No test steps found\n" >> $file
else
    printf "\n" >> $file;
    printf "<table>" >>  $file;
    while IFS= read -r line ; do 
      echo "<tr><td>" >> $file;
      echo $line | sed 's~_~:</td><td>~g' |sed 's/|/\n/g'  >> $file;
      echo "</td></tr>"  >> $file;
    done <<< "$slow_steps"
    printf "</table>" >>  $file;
fi

printf "<h3>%s</h3>" "Workers" >> $file
if [ -z "$worker_list" ]
then
    printf "No workers found\n" >> $file
else
    printf "\n" >> $file;
    printf "<table>" >>  $file;
    while IFS= read -r line ; do 
      echo "<tr><td>" >> $file;
      echo $line | sed 's~_~:</td><td>~g' |sed 's/|/\n/g'  >> $file;
      echo "</td></tr>"  >> $file;
    done <<< "$worker_list"
    printf "</table>" >>  $file;
fi



cat >> $file <<'EOF'
  </body>
EOF