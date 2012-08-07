#!/bin/bash
#
# Convert Windows INI File to BASH4's associative array
#
# Author: Ayumu Koujiya
# URL: https://github.com/AyKo/script/ini2env.sh
#
# Usage: source ini2env.sh [Target INI filename] [value name]
#
# "value name" is optional.
# If "value name" is missing, equivalent to "INIFILE".
#
# ------------------
# For example:
#
# <<test.sh>>
#   source ini2env.sh target.ini INI
#   echo ${INI["Section1.field1"]}
#   echo ${INI["Section1.field2"]}
#   echo ${INI["Section2.field1"]}
# <<target.ini>>
#   [Section1]
#   field1 = 5656
#   field2 = ABCD
#   [Section2]
#   field1 = 4646
#
# $ bash test.sh
# 5656
# ABCD
# 4646
# ------------------
#
# Copyright (c) 2011 Ayumu Koujiya
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

TMPFILE=/tmp/tmpini.$$
if [ "$1" = "" ] ; then
	echo "no input file" 1>&2
	exit 1
fi
trap "/bin/rm -f $TMPFILE" EXIT
cat $1 | gawk -v name="$2" '
BEGIN {
	section = ""
	if (name=="") { name = "INIFILE" }
	separator = "."
	printf("declare -A %s\n", name);
}
/^[[:blank:]]*\[[^\]]*\]/ {
	sub(/^.*\[/, "")
	sub(/\].*/, "")
	gsub(/[\n\r]/, "")
	section = $0
}
/^[[:blank:]]*[^=]+[[:blank:]]*=[[:blank:]]*.+/ {
	sub(/[[:blank:]]*/, "")
	field = substr($0, 1, match($0, /[[:blank:]=]/) - 1)
	sub(/^[^=]*=[[:blank:]]*/, "")
	sub(/[[:blank:]]*$/, "")
	gsub(/[\n\r]/, "")
	gsub(/"/, "\\\"")
	value = $0
	printf("%s[\"%s%s%s\"]=\"%s\"\n", name, section, separator, field, value)
}
' > $TMPFILE
source $TMPFILE

