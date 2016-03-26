#!/bin/bash

# BEGIN WM INFO
ALL_APP_CAT+=':TOOLS'
APP_TOOLS_CAT="Utility and Accessories"
APP_TOOLS_EX="Some usefull tools, utility and accessories."
# END WM INFO

APP_TOOLS_NAME[0]="htop"
APP_TOOLS_PKG[0]="htop" 
APP_TOOLS_DESC[0]="An interactive process viewer for Unix systems"
APP_TOOLS_STAT[0]="OFF"
htop_routine () {
    ALL_PKG_CHOOSEN+=" APP_TOOLS_PKG[0]"
    
}

APP_TOOLS_NAME[1]="gparted"
APP_TOOLS_PKG[1]="gparted" 
APP_TOOLS_DESC[1]="A free partition editor for graphically managing your disk partitions"
APP_TOOLS_STAT[1]="ON"
gparted_routine () {
    ALL_PKG_CHOOSEN+=" APP_TOOLS_PKG[1]"
    
}

APP_TOOLS_NAME[2]="git"
APP_TOOLS_PKG[2]="git" 
APP_TOOLS_DESC[2]="Version Control System"
APP_TOOLS_STAT[2]="ON"
csv_routine () {
    ALL_PKG_CHOOSEN+=" APP_TOOLS_PKG[2]"
    
}

APP_TOOLS_NAME[3]="vcsh"
APP_TOOLS_PKG[3]="vcsh" 
APP_TOOLS_DESC[3]="Version Control System for '$HOME'"
APP_TOOLS_STAT[3]="ON"
csv_routine () {
    ALL_PKG_CHOOSEN+=" APP_TOOLS_PKG[3]"
}

APP_TOOLS_NAME[4]="myRepo"
APP_TOOLS_PKG[4]="mr" 
APP_TOOLS_DESC[4]="Multiple Repository management tool"
APP_TOOLS_STAT[4]="ON"
csv_routine () {
    ALL_PKG_CHOOSEN+=" APP_TOOLS_PKG[4]"
}

