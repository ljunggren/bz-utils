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

total_scenarios="$(jq . $FILE_PATTERN | grep keyword |grep Scenario | wc -l)"
failed_scenarios="$(jq . $FILE_PATTERN | grep status | grep failed | wc -l)"

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

total="$(jq . $FILE_PATTERN | grep status | wc -l)"
failed="$(jq . $FILE_PATTERN | grep status | grep failed | wc -l)"
skipped="$(jq . $FILE_PATTERN | grep status | grep skipped | wc -l)"
pending="$(jq . $FILE_PATTERN | grep status | grep pending | wc -l)"

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
unique_issues="$(cat $FILE_PATTERN | jq -c '.[] |.elements'[0].extraData |jq -c 'select(.rootCase != null)' |jq -c '"\(.rootCase.errHash)_\(.rootCase.desc)_\(.rootCase.type)_\(.rootCase.scope)_#@\(.rootCase.url)@#"' | sed 's/^.//;s/.$//'| sort | uniq -c | sort -r | sed 's/^ *//g' | sed 's/[[:space:]]/\_/')"

printf "\n"
echo $unique_issues
printf "\n"

total_issues="$(echo "$unique_issues" | grep "_" | wc -l)"
tbd_issues="$(echo "$unique_issues" | grep "_null_" | wc -l)"
application_issues="$(echo "$unique_issues" | grep "_app_" | wc -l)"
automation_issues="$(echo "$unique_issues" | grep "_auto_" | wc -l)"
unknown_issues="$(echo "$unique_issues" | grep "_unknow_" | wc -l)"

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

slow_steps="$(cat $FILE_PATTERN | jq -c '.[] |.elements' | jq -c '.[] |.steps'[] | jq '"\(.result.duration/1000000) ms_\(.name)|"' |sort -Vr | head -10 |sed 's/^.//;s/.$//')" 
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

worker_list="$(cat $FILE_PATTERN | jq -c '.[] |.elements'[0].extraData | jq -c '"\(.start)_\(.end)_\(.worker)_\(.id)_\(.name)"' | sed 's/^.//;s/.$//' | sort -k1)"
number_of_workers="$(cat $FILE_PATTERN | jq -c '.[] |.elements'[0].extraData | jq -c '"\(.worker)"' | sed 's/^.//;s/.$//'| sort | uniq | wc -l )"

printf "Number of workers: %s\n" $number_of_workers

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
    <style>

html{font-family:sans-serif;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}a{background-color:transparent}a:active,a:hover{outline:0}input{color:inherit;font:inherit;margin:0;line-height:normal}input[type=checkbox],input[type=radio]{box-sizing:border-box;padding:0}.container{position:relative;width:100%;max-width:1200px;margin:0 auto;padding:0 20px;box-sizing:border-box}.column,.columns{width:100%;float:left;box-sizing:border-box}@media (min-width:400px){.container{width:85%;padding:0}}@media (min-width:550px){.container{width:80%}.column,.columns{margin-left:4%}.column:first-child,.columns:first-child{margin-left:0}.one.column,.one.columns{width:4.66666666667%}.two.columns{width:13.3333333333%}.three.columns{width:22%}.four.columns{width:30.6666666667%}}html{font-size:62.5%}body{font-size:1.5em;line-height:1.6;font-weight:400;font-family:HelveticaNeue,"Helvetica Neue",Raleway,Helvetica,Arial,sans-serif;color:#222;margin:0}h1,h2,h3,h4,h5,h6{margin-top:0;margin-bottom:2rem;font-weight:300}h1{font-size:4rem;line-height:1.2;letter-spacing:-.1rem}h2{font-size:3.6rem;line-height:1.25;letter-spacing:-.1rem}h3{font-size:3rem;line-height:1.3;letter-spacing:-.1rem}h4{font-size:2.4rem;line-height:1.35;letter-spacing:-.08rem}h5{font-size:1.8rem;line-height:1.5;letter-spacing:-.05rem}h6{font-size:1.5rem;line-height:1.6;letter-spacing:0}@media (min-width:550px){h1{font-size:5rem}h2{font-size:4.2rem}h3{font-size:3.6rem}h4{font-size:3rem}h5{font-size:2.4rem}h6{font-size:1.5rem}}p{margin-top:0}td,th{padding:9px 15px;text-align:left;border-bottom:1px solid #e1e1e1}td:first-child,th:first-child{padding-left:5px}td:last-child,th:last-child{padding-right:5px}.button,button{margin-bottom:1rem}fieldset,input,select,textarea{margin-bottom:1.5rem}blockquote,dl,figure,form,ol,p,pre,table,ul{margin-bottom:2.5rem}.container:after,.row:after,.u-cf{content:"";display:table;clear:both}    

.top_header{margin:7rem 0}.top_header .heading{font-size:3rem;color:#404159}.chart_section table,.tabs_section table{width:100%;border-collapse:collapse;border-spacing:0}.chart_section table tr,.tabs_section table tr{padding:.5rem .5rem}.chart_section table th,.tabs_section table th{color:rgba(43,44,59,.8);font-size:1.1rem;text-transform:uppercase}.chart_section{margin-bottom:6rem}.chart_section .table_area{margin-bottom:2rem}@media all and (min-width:768px){.chart_section .table_area{margin-bottom:0}}.chart_section .table_area.last_of-type{margin:0}.chart_section .table_area .table_header{border-top-right-radius:5px;border-top-left-radius:5px;padding:1.1rem 1rem}.chart_section .table_area .table_header h6{margin-bottom:0;font-weight:600;font-size:1.3rem}.chart_section .table_area .table_header.test{background:#f99fa0}.chart_section .table_area .table_header.steps{background:#fdcedc}.chart_section .table_area .table_header.issues{background:#ded0fb}.chart_section .table_area .table_header.workers{background:#b9dfd4}.chart_section .table_area th{padding:0 .9rem!important;width:70%}.chart_section .table_area td{font-size:1.4rem}.tabs_section{margin-bottom:6rem}.tabs_section tr:nth-of-type(even){background-color:rgba(0,0,0,.05)}.tabs_section tr td{font-size:1.3rem}footer{padding:2rem 0}footer .copy{font-size:1rem}.tabset>input[type=radio]{position:absolute;left:-200vw}.tab-panels>section{padding:1rem}.tabset .tab-panel{display:none;overflow-x:auto;white-space:nowrap}.tabset>input:first-child:checked~.tab-panels>.tab-panel:first-child,.tabset>input:nth-child(11):checked~.tab-panels>.tab-panel:nth-child(6),.tabset>input:nth-child(3):checked~.tab-panels>.tab-panel:nth-child(2),.tabset>input:nth-child(5):checked~.tab-panels>.tab-panel:nth-child(3),.tabset>input:nth-child(7):checked~.tab-panels>.tab-panel:nth-child(4),.tabset>input:nth-child(9):checked~.tab-panels>.tab-panel:nth-child(5){display:block}.tabset>label{position:relative;display:inline-block;padding:1.1rem 1rem;padding-right:3rem;cursor:pointer;font-weight:600;border-top-left-radius:5px;border-top-right-radius:5px;border-bottom:3px solid transparent;margin-bottom:-1px;transition:all .4s ease-in;width:80%;font-size:1.3rem}.tabset>label:hover{background-color:rgba(0,0,0,.05)}@media all and (min-width:768px){.tabset>label{width:auto}}.tabset>input:checked+label{border-color:#e1e1e1;border-bottom:1px solid #fff;border-bottom:3px solid #1183ee}.tab-panel{border-top:1px solid #e1e1e1}

    </style>     
    <title>Boozang - Test Execution Summary</title>
  </head>
  <body>
    <div class="container">
        <header class="top_header">
            <h1 class="heading">Test Execution Summary</h1>
        </header>
        <section class="chart_section">
            <div class="row">
                <div class="three columns">
                    <article class="table_area">
                        <header class="table_header test">
                            <h6>Test Scenarios</h6>
                        </header>
                        <table>
                            <thead></thead>
                            <tbody>
                                <tr>
                                <th>Total</th>


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
                <div class="three columns">
                    <article class="table_area">
                        <header class="table_header steps">
                            <h6>Test Steps</h6>
                        </header>
                        <table>
                            <thead></thead>
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
                <div class="three columns">
                    <article class="table_area">
                        <header class="table_header issues">
                            <h6>Issues</h6>
                        </header>
                        <table>
                            <thead></thead>
                            <tbody>
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
                <div class="three columns">
                    <article class="table_area">
                        <header class="table_header workers">
                            <h6>Workers</h6>
                        </header>
                        <table>
                            <thead></thead>
                            <tbody>
                                <tr>
                                    <th>Total</th>
EOF
printf "<td>%s</td>" $number_of_workers >> $file
cat >> $file <<'EOF'
                                </tr>
                            </tbody>
                        </table>
                    </article>
                </div>
            </div>
        </section>
EOF

cat >> $file <<'EOF'
        <!-- tabs -->
        <section class="tabs_section">
            <div class="tabset">
                <!-- Tab 1 -->
                <input type="radio" name="tabset" id="tab1" aria-controls="issues" checked>
                <label for="tab1">Issue Overview</label>
                <!-- Tab 2 -->
                <input type="radio" name="tabset" id="tab2" aria-controls="steps">
                <label for="tab2">Slowest Test Steps</label>
                <!-- Tab 3 -->
                <input type="radio" name="tabset" id="tab3" aria-controls="workers">
                <label for="tab3">Workers Job Log</label>

                <div class="tab-panels">
                    <section id="issues" class="tab-panel">
                        <table>
                            <thead>
                                <tr>
                                    <th scope="col">Impact</th>
                                    <th scope="col">Error Hash</th>
                                    <th scope="col">Description</th>
                                    <th scope="col">Type</th>
                                    <th scope="col">Scope</th>
                                    <th scope="col">Url</th>
                                </tr>
                            </thead>
                            <tbody>

EOF

if [ -z "$unique_issues" ]
then
    printf "<tr><td>No issues found</td></tr>" >> $file
else
    while IFS= read -r line ; do 
      echo "<tr><td>" >> $file;
      echo $line | sed 's~_~</td><td>~g' | sed 's/\s+/,/' |sed 's/|/\n/g' |sed 's/#@null@#/-/g' | sed 's/null/-/g' |sed 's/#@/\<a href="/g' |sed 's/@#/" target="_blank">Go\<\/a>/g'   >> $file;
      echo "</td></tr>"  >> $file;
    done <<< "$unique_issues"
    printf "</table>" >>  $file;
fi

cat >> $file <<'EOF'                                
                           </tbody>
                        </table>
                    </section>
                    <section id="steps" class="tab-panel">
                        <table>
                            <thead>
                                <tr>
                                    <th>Time</th>
                                    <th>Test Step</th>
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
                    </section>
                    <section id="workers" class="tab-panel">
                        <table>
                            <thead>
                                <tr>
                                     <th scope="col">Start</th>
                                      <th scope="col">End</th>
                                      <th scope="col">Worker</th>
                                      <th scope="col">Test id</th>
                                      <th scope="col">Test name</th>
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
      echo $line | sed 's~_~</td><td>~g' |sed 's/|/\n/g'  >> $file;
      echo "</td></tr>"  >> $file;
    done <<< "$worker_list"
    printf "</table>" >>  $file;
fi

cat >> $file <<'EOF'   
                            </tbody>
                         </table>
                    </section>
                </div>
            </div>
        </section>
        <footer>
            <p class="copy"> &copy; 2021 - Boozang INC. ALL RIGHTS RESERVED. </p>
        </footer>
    </div>
</body>

</html>

EOF

now=$(date +"%Y-%m-%d")

csvfile=$(echo bz-issues-$now.csv)
printf "%s\n" Generating CSV issue file: $csvfile


if [ -z "$unique_issues" ]
then
    printf "<tr><td>No issues found. No CSV file exported.</td></tr>" >> $csvfile
else
    while IFS= read -r line ; do 
      echo $line | sed 's~_~,~g' | sed 's/\s+/,/' |sed 's/|/\n/g' |sed 's/#@null@#/-/g' | sed 's/null/-/g' |sed 's/#@/\,/g' |sed 's/@#//g'   >> $csvfile;    
    done <<< "$unique_issues"
   
fi

# Return error code if any non-automation issues exists
if [ -z "$unique_issues" ] || [ "$total_issues" == "$automation_issues" ]
then
  echo "No non-automation issues found. Exiting with status code 0"
  exit 0
else
  echo "Issues found. Exiting with status code 1"
  exit 1
fi
