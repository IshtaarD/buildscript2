#!/bin/bash 

# Ishtaar Desravines
# 2022-08-11
# This script checks for system processes that exceeds a certain percentage of memory and asked the users to either terminate a process or allow it to run, then confirms the running processes at the end. 

# Actions that will break the script:
# i. If you kill the process with command name gnome-shell, the script stops running because the terminal is terminated and no longer active. 
# ii. If you terminate a parent process, the child processes may no longer be found. The script will keep running but there may be a error message saying " 


systemMem=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}') #  outputs the line that has a match to MemTotal and takes the  2nd field and divides it by 1024 to get the memory from KB to MB.
topTen=$(ps -eo pid,ppid,command,%mem --sort=-%mem | head -n 11) # output of ps command to show the first 10 processes using the most memory with the header and assigning it to variable topTen.
memList=$(ps -eo pid,%mem,comm --sort=-%mem) # output of ps command sorted by memory. Used this variable to pull pids from in for loop below. 

echo "-----------------------------------------------------------------------------------------------------------"
echo "WELCOME TO YOUR SYSTEM PROCESSES' MEMORY USAGE CHECKER"
echo "-----------------------------------------------------------------------------------------------------------"
echo "These are the top ten processes using the most memory on your system." 
echo "------------------------------------------------------------------------------------------------------------"
echo "$topTen"
echo "------------------------------------------------------------------------------------------------------------"
read -p "Your system currently has $systemMem MB of memory. What percentage of memory should processes not exceed? " threshold #asks the user what the memory threshold should be and assigns that value to the variable threshold. 

while [[ -n ${threshold//[0-9,.]} ]] # this while loop checks to see if the user inputted a number with or without a decimal. If the user inputs any characters besides numbers or a period, it will keep prompting the user to enter a number.
do
	read -p "Please enter a number. " threshold
done


echo "------------------------------------------------------------------------------------------------------------"
read -p 'The processes running on your system that currently exceed '$threshold' percent of memory usage will be shown next. You must select "Y" or "N" for each process to either TERMINATE or leave ACTIVE. Would you like to continue? ' answer # asks the user if they would like to see the processes that are exceeding the threshold and tells them they will have to enter Y or N when prompted. 
echo "------------------------------------------------------------------------------------------------------------"

answer=$(echo $answer | cut -c 1 | tr [A-Z] [a-z]) # takes the input assigned to the answer variable and cuts it to the first character and switches the character to lowercase, in case the user enters YES, NO, Y, N, or these options in a combination of uppercase and lowercase. 

while [[ $answer != 'y' && $answer != 'n' ]] # this while loop keeps prompting the user to answer Y or N  if they input any other words or characters other than Y, N, YES, NO, or these options ina combination of uppercase and lowercase. 
        do 
                read -p 'Please enter valid option "Y" or "N": ' answer
                answer=$(echo $answer | cut -c 1 | tr [A-Z] [a-z])
        done

process2term=$(ps -eo pid,%mem,comm --sort=-%mem | awk '($2>'$threshold'){print $1}') #takes the output of the ps command, filters out the pid, command name, and memory %, and compares the value of the second field (memory %) to the value assigned to the threshold variable by the user and prints out the pid of any process that has a memory % greater than the value assigned to the threshold variable.

if [ $answer = 'y' ] # if statement, if the user chooses Y, go through the process of terminating or leaving processes active. If the user chooses no, tell the user to run the script again if they want to free up resources. 
   then
	for pid in $process2term; # for loop; for each pid that is in the variable process2term, print out the header (PID, MEM%, COMMAND) and then print out the line from variable memList with the matching pid. Variable memList is defined at the beginning of script  
		do
			echo "$memList" | head -n 1
			echo "$memList" | grep $pid
		
			echo
	 		read -p 'Would you like to terminate this process? "Y" or "N": ' answer
			answer=$(echo $answer | cut -c 1 | tr [A-Z] [a-z])			

			if [ $answer = 'y' ] # asks user if they want to terminate the process and allows the user to input their selection. 
			then
					if [[ -z $(echo $memList | grep $pid) ]]; #attempted to us this if statement to solve the issue when a parent process is terminated and the child process can no longer be found. I wanted to if statement to research the process list for the pid and if it returns nothing then it tells the user the process is no longer active. 
					then 
						echo "Process is no longer active. You may have terminated its parent process"
					else 
						echo "$cName Process with PID $pid has been TERMINATED"
						kill -15 $pid 
						echo "-----------------------------------------------------------------"
					fi
			else
				
				echo $pid >> ~/Desktop/activePid.txt #output the processes pids that the user did not want to terminate to a file on desktop with the current date and time in the file name. 
				echo "Process with PID $pid is still ACTIVE"
				echo "-----------------------------------------------------------------"
			fi;
	done

elif [ $answer = 'n' ] 
    then 
	echo "Run this script again if you'd like to free up some resources."
fi


echo "PROCESSES EXCEEDING $threshold PERCENT MEMORY YOU DECIDED NOT TO TERMINATE:"  #shows the user which processes they decided not to terminate though they are above the threshold. 
echo "$memList" | head -n 1 

for pidA in $(cat ~/Desktop/activePid.txt); #for loop to check each of the pids of the left over active processes in the file and to print them if it is still active. 
	do
	echo "$memList" | grep $pidA; 
done
	echo "----------------------------------------------------------------"
	echo "If you want to terminate these processes you left active, please run the script again!"
