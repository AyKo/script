#!/bin/bash
#
# Poor plain text-based key-value database in shell script
#
# Author: Ayumu Koujiya
# URL: https://github.com/AyKo/script/poortxtdb.sh
#
# Usage: poortxtdb [DB file] [command] [parameter]..
#
# command:
#   - get [key]
#   - set [key] [value]
#   - add [key] [value] 
#   - delete [key]
#
# ----------------------------------------------------------------------------
# Copyright (c) 2012 Ayumu Koujiya
#
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the 
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

dbname=$1
command=$2
param1=$3
param2=$4
if [ "${dbname}" == "${dbname%/*}" ]; then
    tmpname=./tmp.$$
else
    tmpname=${dbname%/*}/tmp.$$
fi

function ShowError_KeyNotFound() {
    echo "error: '$param1' is not found in $dbname." >&2
}

function ShowError_KeyDuplicate() {
    echo "error: '$param1' is duplicate in $dbname." >&2
}

function ShowError_General() {
    echo "error: failure. code=$errcode" >&2
}

function Get() {
    grep -e "^${param1}	.*" $dbname
    if [ $? -ne 0 ]; then
        ShowError_KeyNotFound
    fi
}

function Set() {
    trap "/bin/rm -f $tmpname" EXIT
    gawk "BEGIN{FS=\"\\t\";errcode=100} END{exit errcode} \$1~/^${param1}$/{print(\"${param1}\\t${param2}\");errcode=0;next} {print \$0}" < $dbname > $tmpname
    errcode=$?
    if [ $errcode -eq 0 ] ; then
        /bin/mv $tmpname $dbname
    elif [ $errcode -eq 100 ]; then
        ShowError_KeyNotFound
    else
        ShowError_General
    fi
    return $errcode
}

function Add() {
    grep -e "^${param1}	.*" $dbname > /dev/null 2> /dev/null
    errcode=$?
    if [ $errcode -eq 1 ]; then
        trap "/bin/rm -f $tmpname" EXIT
        /bin/cp $dbname $tmpname && echo "${param1}	${param2}" >> $tmpname
        /bin/mv $tmpname $dbname
        errcode=$?
        if [ $errcode -ne 0 ]; then
            ShowError_General
        fi
    elif [ $errcode -eq 0 ]; then
        ShowError_KeyDuplicate
    else
        ShowError_General
    fi
    return $errcode
}

function Delete() {
    trap "/bin/rm -f $tmpname" EXIT
    gawk "BEGIN{FS=\"\\t\";errcode=100} END{exit errcode} \$1~/^${param1}$/{errcode=0;next} {print \$0}" < $dbname > $tmpname
    errcode=$?
    if [ $errcode -eq 0 ] ; then
        /bin/mv $tmpname $dbname
    elif [ $errcode -eq 100 ]; then
        ShowError_KeyNotFound
    else
        ShowError_General
    fi
    return $errcode
}

function ShowUsage() {
cat <<_EOF_
Poor plain text-based database in shell script.
poortxtdb [DB file] [command] [key] [value]
command:
  - get [key]
  - set [key] [value]
  - add [key] [value] 
  - delete [key]
_EOF_
}

if [ "$dbname" = "" -o "$command" = "" ]; then
    ShowUsage
    exit 1
fi
if [ ! -f $dbname ] && [ "$command" -ne "add" ]; then
    echo "error: $dbname is not regular file" >&2
    exit 1
fi

case "$command" in
    "get") Get ;;
    "set") Set ;;
    "add") Add ;;
    "delete") Delete ;;
    *) echo "error: $command is unrecognized command." >&2
esac

# vim: ts=4 sts=4 sw=4 expandtab
