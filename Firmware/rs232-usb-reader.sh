#/bin/bash

#export LC_ALL=C #disabilito multybyte/wide chars

export LANG=C.UTF-8
stty 2400 -echo -F /dev/ttyUSB0
if [ "$1" == "1" ]; then 
 hexdump -v -e '/1 "%u\n"' /dev/ttyUSB0
elif [ "$1" == "2" ]; then
 while read -rn1 c;do echo "$c="|rev|cut -c2-|rev;printf '%d' "'$c";echo "";done< /dev/ttyUSB0
elif [ "$1" == "3" ]; then
 while read -rn1 c;do printf "$c";done< /dev/ttyUSB0
else
 while read c;do echo "$c";done< /dev/ttyUSB0
fi
