#!/bin/bash

# BEGIN OFFICE INFO
ALL_APP_CAT+=':OFFICE'
APP_OFFICE_CAT="Office"
APP_OFFICE_EX="Office Application"
# END OFFICE INFO

idx=0

APP_OFFICE_NAME[idx]="LibreOffice"
APP_OFFICE_PKG[idx]="libreoffice"
APP_OFFICE_DESC[idx]="Open source Office suite"
APP_OFFICE_STAT[idx]="OFF"
(( idx++ ))

APP_OFFICE_NAME[idx]="TexLive Full"
APP_OFFICE_PKG[idx]="texlive-full"
APP_OFFICE_DESC[idx]="The complete suite of LaTex"
APP_OFFICE_STAT[idx]="OFF"
(( idx++ ))
