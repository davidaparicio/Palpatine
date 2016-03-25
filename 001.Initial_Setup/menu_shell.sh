#!/bin/bash

ALL_APP_CAT+='SHELL'


declare -A APP_SHELL
# https://en.wikipedia.org/wiki/Unix_shell sh 	ksh 	csh 	tcsh 	bash 	zsh
APP_SHELL_WIDTH=4

APP_SHELL_NAME[0]="sh"
APP_SHELL_PKG[0]="xubuntu-desktop" 
APP_SHELL_DESC[0]="Full well known desktop manager based on xfce"
APP_SHELL_STAT[0]="OFF"

Xubuntu_Desktop_routine () {
  # TODO : routine is called just before running apt-get or other manager.
  # It should add repo if necessary and add the right package to the list of all package to setup
}

