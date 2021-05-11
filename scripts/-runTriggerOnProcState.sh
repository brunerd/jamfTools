#!/bin/bash
#Joel Bruner

#the process name that will be tested
process="${4}"

#if it "IS" or "NOT"* running
condition="${5:-NOT}"

function jamflog {
	local logFile="{$2:-/var/log/jamf.log}"
	#if it exists but we cannot write to the log or it does not exist, unset and tee simply echoes
	[ -e "${logFile}" -a ! -w "${logFile}" ] && unset logFile
	#this will tee to jamf.log in the jamf log format: <Day> <Month> DD HH:MM:SS <Computer Name> ProcessName[PID]: <Message>
	echo "$(date +'%a %b %d %H:%M:%S') ${myComputerName:="$(scutil --get ComputerName)"} ${myName:="$(basename "${0%.*}")"}[${myPID:=$$}]: ${1}" | tee -a "${logFile}" 2>/dev/null
}

#ensure we have something for process name 
if [ -z "${4}" ]; then
    jamflog "No process name given, exiting"
    exit 1
fi

#make sure have something, test all parameters
if [ -z "${6}${7}${8}${9}${10}${11}" ]; then
    jamflog "No arguments given, exiting"
    exit 1
fi

#if process exists and condition is for to NOT be running then bail
if pgrep "${process}" &>/dev/null && [ "${condition}" = "NOT" ]; then
	jamflog "Exiting. Condition NOT and process IS running: ${process} ($(pgrep "${process}"))"
	exit
elif ! pgrep "${process}" &>/dev/null && [ "${condition}" = "IS" ]; then
	jamflog "Exiting. Condition IS and process is NOT running: ${process}"
	exit
elif pgrep "${process}" &>/dev/null && [ "${condition}" = "IS" ]; then
	jamflog "Continuing. Condition IS and process IS running: ${process} ($(pgrep "${process}"))"
elif ! pgrep "${process}" &>/dev/null && [ "${condition}" = "NOT" ]; then
	jamflog "Continuing. Condition NOT and process is NOT running: ${process}"
fi

#change IFS to tab and newline
IFS=$'\t\n'
#put parameters 4-11 in an array
argArray=( ${6} ${7} ${8} ${9} ${10} ${11} )

#loop through array, start with array element 0
for (( i=0; i < ${#argArray[@]}; i++ )); do
	#get event item from the array
    item="${argArray[$i]}"

	#skip empty events or those "commented" out code with a #
    if [ "${item:0:1}" == "#" -o -z "${item}" ]; then
		echo "Skipping item ${i}: ${item}"
		continue
    fi
    
    jamflog "Executing: jamf policy -event \"${item}\""
    #send output to null the policy itself will be capturing it's output and logging it
    jamf policy -event "${item}" 2>/dev/null 1>&2
    jamflog "Finished: jamf policy -event \"${item}\", exit code: $?"
done

exit 0
