#!/bin/bash

# BEGIN WWW INFO
ALL_APP_CAT+=':WWW'
APP_WWW_CAT="Internet"
APP_WWW_EX="Set of internet related apps"
# END WWW INFO

idx=0

APP_WWW_NAME[idx]="Firefox"
APP_WWW_PKG[idx]="firefox"
APP_WWW_DESC[idx]="Well known internet browers"
APP_WWW_STAT[idx]="ON"
(( idx++ ))

APP_WWW_NAME[idx]="Thunderbird"
APP_WWW_PKG[idx]="thunderbird"
APP_WWW_DESC[idx]="Well known email client"
APP_WWW_STAT[idx]="ON"
(( idx++ ))

APP_WWW_NAME[idx]="Deluge"
APP_WWW_PKG[idx]="deluge"
APP_WWW_DESC[idx]="BitTorrent client"
APP_WWW_STAT[idx]="ON"
(( idx++ ))
