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

echo $unique_issues

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
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-giJF6kkoqNQ00vy+HMDP7azOuL0xtbfIcaT9wjKHr8RbDVddVHyTfAAsrekwKmP1" crossorigin="anonymous">
    <link rel="stylesheet" href="http://cdn.boozang.com/css/style.css">
    <title>Boozang - Test Execution Summary</title>
  </head>
  <body>
      <header class="top_header">
        <div class="container">
            <div class="row">
              <div class="col">
                <h1 class="heading">Boozang Test Execution Summary</h1>
              </div>
            </div>
          </div>
      </header>
EOF

cat >> $file <<'EOF'
      <section class="chart_section">
        <div class="container">
            <div class="row">
              <div class="col-sm">
                  <article class="table_area">
                    <header class="table_header test">
                        <h6>Test Scenarios</h6>
                      </header>
                    <table class="table">
                        <tbody>
                          <tr>
                            <th scope="row">Total</th>
EOF
printf "<td>%s</td>" $total_scenarios >> $file
cat >> $file <<'EOF'
                          </tr>
                          <tr>
                            <th scope="row">Failed</th>
EOF
printf "<td>%s</td>" $failed_scenarios >> $file
cat >> $file <<'EOF'
                          </tr>
                        </tbody>
                      </table>
                  </article>
              </div>
              <div class="col-sm">
                <article class="table_area">
                <header class="table_header steps">
                    <h6>Test Steps</h6>
                </header>
              <table class="table">
                  <tbody>
                    <tr>
                      <th scope="row">Total</th>
EOF
printf "<td>%s</td>" $total >> $file
cat >> $file <<'EOF'
                    </tr>
                    <tr>
                      <th scope="row">Failed</th>
EOF
printf "<td>%s</td>" $failed >> $file
cat >> $file <<'EOF'
                   </tr>
                    <tr>
                        <th scope="row">Skipped</th>
EOF
printf "<td>%s</td>" $skipped >> $file
cat >> $file <<'EOF'
                      </tr>
                      <tr>
                        <th scope="row">Pending</th>
EOF
printf "<td>%s</td>" $pending >> $file
cat >> $file <<'EOF'

                      </tr>
                  </tbody>
                </table>
            </article>
            </div>
            <div class="col-sm">
                <article class="table_area">
                <header class="table_header issues">
                  <h6>Issues</h6>
                </header>
              <table class="table">
                  <tbody>
                    <tr>
                      <th scope="row">Total</th>
EOF
printf "<td>%s</td>" $total_issues >> $file
cat >> $file <<'EOF'

                    </tr>
                    <tr>
                      <th scope="row">To be defined</th>
EOF
printf "<td>%s</td>" $tbd_issues >> $file
cat >> $file <<'EOF'

                    </tr>
                    <tr>
                      <th scope="row">Application</th>
EOF
printf "<td>%s</td>" $application_issues >> $file
cat >> $file <<'EOF'

                    </tr>
                    <tr>
                        <th scope="row">Automation</th>
EOF
printf "<td>%s</td>" $automation_issues >> $file
cat >> $file <<'EOF'

                      </tr>
                      <tr>
                        <th scope="row">Unknown</th>
EOF
printf "<td>%s</td>" $unknown_issues >> $file
cat >> $file <<'EOF'

                      </tr>
                  </tbody>
                </table>
                </article>
            </div>
            <div class="col-sm">
                <article class="table_area">
                <header class="table_header workers">
                    <h6>Workers</h6>
                </header>
              <table class="table">
                  <tbody>
                    <tr>
                      <th scope="row">Total</th>
                      <td>7</td>
                    </tr>
                  </tbody>
                </table>
                </article>
            </div>
            </div>
          </div>
      </section>
EOF

cat >> $file <<'EOF'

   <section class="tabs_section">
            <div class="container">
                <div class="row">
                    <!-- nav tabs -->
                    <ul class="nav nav-tabs" id="myTab" role="tablist">
                        <li class="nav-item" role="presentation">
                          <a class="nav-link active issues" id="home-tab" data-bs-toggle="tab" href="#issues" role="tab" aria-controls="issues" aria-selected="true">Issue Overview</a>
                        </li>
                        <li class="nav-item" role="presentation">
                          <a class="nav-link steps" id="profile-tab" data-bs-toggle="tab" href="#steps" role="tab" aria-controls="steps" aria-selected="false">Slowest Test Steps</a>
                        </li>
                        <li class="nav-item" role="presentation">
                          <a class="nav-link workers" id="contact-tab" data-bs-toggle="tab" href="#workers" role="tab" aria-controls="workers" aria-selected="false">Workers Job Log</a>
                        </li>
                      </ul>
                           <!-- nav content -->
                      <div class="tab-content" id="myTabContent">
                        <div class="tab-pane fade show active" id="issues" role="tabpanel" aria-labelledby="issues-tab">
                            <table class="table table-striped">
                                <thead>
                                    <tr>
                                      <th scope="col">Hash</th>
                                      <th scope="col">#</th>
                                      <th scope="col">Description</th>
                                      <th scope="col">Type</th>
                                      <th scope="col">Url</th>
                                    </tr>
                                  </thead>
                            <tbody>
                               
EOF

if [ -z "$unique_issues" ]
then
    printf "<tr><td>No test steps found</td></tr>" >> $file
else
    while IFS= read -r line ; do 
      echo "<tr><td>" >> $file;
      echo $line | sed 's~_~</td><td>~g' |sed 's/|/\n/g'  >> $file;
      echo "</td></tr>"  >> $file;
    done <<< "$unique_issues"
    printf "</table>" >>  $file;
fi

cat >> $file <<'EOF'                                
                            </tbody>
                        </table>
                        </div>
                        <div class="tab-pane fade" id="steps" role="tabpanel" aria-labelledby="steps-tab">
                            <table class="table table-striped">
                                <thead>
                                    <tr>
                                      <th scope="col">Time</th>
                                      <th scope="col">Test Step</th>
                                    </tr>
                                  </thead>
                            <tbody>
EOF

if [ -z "$slow_steps" ]
then
    printf "<tr><td>No test steps found</td></tr>" >> $file
else
    while IFS= read -r line ; do 
      echo "<tr><td>" >> $file;
      echo $line | sed 's~_~</td><td>~g' |sed 's/|/\n/g'  >> $file;
      echo "</td></tr>"  >> $file;
    done <<< "$slow_steps"
    printf "</table>" >>  $file;
fi

cat >> $file <<'EOF'   
                            </tbody>
                        </table>
                        </div>
                        <div class="tab-pane fade" id="workers" role="tabpanel" aria-labelledby="workers-tab">
                            <table class="table table-striped">
                                <thead>
                                    <tr>
                                      <th scope="col">Completion Time</th>
                                      <th scope="col">Worker</th>
                                      <th scope="col">Job</th>
                                    </tr>
                                  </thead>
                            <tbody>
EOF

if [ -z "$worker_list" ]
then
    printf "<tr><td>No workers found</td></tr>" >> $file
else
    while IFS= read -r line ; do 
      echo "<tr><td>" >> $file;
      echo $line | sed 's~_~:</td><td>~g' |sed 's/|/\n/g'  >> $file;
      echo "</td></tr>"  >> $file;
    done <<< "$worker_list"
    printf "</table>" >>  $file;
fi

cat >> $file <<'EOF'   
                            </tbody>
                        </table>
                        </div>
                      </div>
                </div>
            </div>
        </section>

        <footer>
            <div class="container">
                <div class="row">
                    <div class="col">
                        Something here in the footer too?...
                    </div>
                </div>
            </div>
        </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta1/dist/js/bootstrap.bundle.min.js" integrity="sha384-ygbV9kiqUc6oa4msXn9868pTtWMgiQaeYH7/t7LECLbyPA2x65Kgf80OJFdroafW" crossorigin="anonymous"></script>
  </body>
</html>

EOF