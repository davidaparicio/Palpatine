#!/bin/bash

ask_continue() {
	# In case of aborting save callback function to know from which point to 
  # to continue in case of aborting.
	CALLBACK=$2
	read -p 'Ready to continue ? [Y/n]' yn;
  echo $yn
	if [[ ! $yn == [NnYy] ]]
	then
		echo 'Please enter Yy or Nn'
    ask_continue
	elif [[ $yn == [Nn] ]]
	then 
		echo "$(date) : User do not want to continue from ${CALLBACK}" >> setup.log
	fi
}
