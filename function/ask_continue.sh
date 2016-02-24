#!/bin/bash

ask_continue() {
	# In case of aborting save callback function to know from which point to 
  	# to continue in case of aborting.
  	local DEFAULT_YN="Y"
	CALLBACK=$1
	read -p 'Ready to continue ? [Y/n]' yn
	yn=${yn:-$DEFAULT_YN}
	if [[ $yn == [Nn] ]]
	then 
		echo "[LOG] - $(date) : User do not want to continue from ${CALLBACK}" >> setup.log
	fi
}
