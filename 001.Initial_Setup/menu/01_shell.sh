#!/bin/bash

# BEGIN WM INFO
ALL_APP_CAT+=":SHELL"
APP_SHELL_CAT="Shell"
APP_SHELL_EX="A set of Bourne Shell"
# END WM INFO

APP_SHELL_NAME[0]="ash"
APP_SHELL_PKG[0]="ash" 
APP_SHELL_DESC[0]="Written as a BSD-licensed replacement for the Bourne Shell"
APP_SHELL_STAT[0]="ON"
ash_routine () {
	ALL_PKG_CHOOSEN+=" APP_SHELL_PKG[0]"
}

APP_SHELL_NAME[1]="dash"
APP_SHELL_PKG[1]="dash" 
APP_SHELL_DESC[1]="A modern replacement for ash in Debian and Ubuntu"
APP_SHELL_STAT[1]="ON"
dash_routine () {
	ALL_PKG_CHOOSEN+=" APP_SHELL_PKG[1]"
}

APP_SHELL_NAME[2]="mksh"
APP_SHELL_PKG[2]="mksh" 
APP_SHELL_DESC[2]="A descendant of the OpenBSD /bin/ksh and pdksh, developed as part of MirOS BSD"
APP_SHELL_STAT[2]="OFF"
mksh_routine () {
	ALL_PKG_CHOOSEN+=" APP_SHELL_PKG[2]"
}

APP_SHELL_NAME[3]="zsh"
APP_SHELL_PKG[3]="zsh" 
APP_SHELL_DESC[3]="A relatively modern shell that is backward compatible with bash"
APP_SHELL_STAT[3]="ON"
zsh_routine () {
	ALL_PKG_CHOOSEN+=" APP_SHELL_PKG[3]"
}
