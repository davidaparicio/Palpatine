#!/bin/bash

# Variable preset
HOSTNAME=$(hostname)

# Variable to set
HOSTNAME_WANTED='hostname'

# Array to store user information and user to create.
USER_FNAME=('usr1 first name' 'usr2 first name')
USER_LNAME=('usr1 last name' 'usr2 last name')
USER_MAIL=('usr1.email@exemple.com' 'usr2.email@example.com')
USER_ACCOUNT=('usr1account' 'usr2account')

###############################################################################
#                                  WARNING                                    #
###############################################################################
#                                                                             #
# Root user is not configured by default, if you want him to be included into #
# during configuration of the setup, for getting hist dotfiles, project, etc. #
# You will have to add it to the arrays of user.                              #
#                                                                             #
# Example :                                                                   #
# USER_FNAME=('root first name' 'usr1 first name')                            #
# USER_LNAME=('root last name' 'usr1 last name')                              #
# USER_MAIL=('root.email@exemple.com' 'usr1.email@example.com')               #
# USER_ACCOUNT=('root' 'usr2account')                                         #
#                                                                             #
###############################################################################
