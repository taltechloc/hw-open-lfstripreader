#! /bin/sh
#limit for a no change, overcaming it means at least a weak responce
no=2
#separation between weak and strong
weak=4

echo "Please provide the file name for the logging: (ENTER to skip logging):"
read filename
echo "Switching ON the heater (Blue LED, demonstration purpose only)."
wget -t 2 192.168.4.1/on -o /dev/null -O /dev/null
sleep 1
echo "Switching OFF the heater (Blue LED, demonstration purpose only)."
wget -t 2 192.168.4.1/off -o /dev/null -O /dev/null
sleep 1
echo "Switching ON the heater (Blue LED, demonstration purpose only)."
wget -t 2 192.168.4.1/on -o /dev/null -O /dev/null
sleep 1
echo "Switching OFF the heater (Blue LED, demonstration purpose only)."
wget -t 2 192.168.4.1/off -o /dev/null -O /dev/null
sleep 1

while :; do
 string=$(wget -t 2 192.168.4.1 -o /dev/null -O /dev/stdout)
 if [ "$?" != "0" -o "$string" = "" ]; then
  string=$(wget -t 2 192.168.4.1 -o /dev/null -O /dev/stdout)
 fi
 if [ "$filename" != "" ]; then
  echo "$(date +%s): $string">>"${filename}_raw.txt"
 fi
 #Error checking on the string
 err=$(echo "$string"|grep "^PIC response: Hello! C="|grep "B$")
 c=''
 if [ "$err" = "" ]; then
  echo "Data reading was not successful. Retrying.."
  echo "Responce was $string"
 else
  clear
  R1=$(echo "$string"|tr " " "\n"|grep "R1=")
  R2=$(echo "$string"|tr " " "\n"|grep "R2=")
  R3=$(echo "$string"|tr " " "\n"|grep "R3=")
  R4=$(echo "$string"|tr " " "\n"|grep "R4=")
  r1=$(echo "$string"|tr " " "\n"|grep "r1=")
  r2=$(echo "$string"|tr " " "\n"|grep "r2=")
  r3=$(echo "$string"|tr " " "\n"|grep "r3=")
  r4=$(echo "$string"|tr " " "\n"|grep "r4=")
  #just the readed numbers
  N1=$(echo "$R1"|cut -c4-)
  n1=$(echo "$r1"|cut -c4-)
  N2=$(echo "$R2"|cut -c4-)
  n2=$(echo "$r2"|cut -c4-)
  N3=$(echo "$R3"|cut -c4-)
  n3=$(echo "$r3"|cut -c4-)
  N4=$(echo "$R4"|cut -c4-)
  n4=$(echo "$r4"|cut -c4-)
  #deltas
  D1=$((10#$n1-10#$N1))
  spazi=$((4-$(echo "$D1"|wc -c)))
  while [ "$spazi" -gt "0" ];do
   D1=$(echo " $D1")
   spazi=$(($spazi-1))
  done  
  D2=$((10#$n2-10#$N2))
  spazi=$((4-$(echo "$D2"|wc -c)))
  while [ "$spazi" -gt "0" ];do
   D2=$(echo " $D2")
   spazi=$(($spazi-1))
  done
  D3=$((10#$n3-10#$N3))
  spazi=$((4-$(echo "$D3"|wc -c)))
  while [ "$spazi" -gt "0" ];do
   D3=$(echo " $D3")
   spazi=$(($spazi-1))
  done
  D4=$((10#$n4-10#$N4))
  spazi=$((4-$(echo "$D4"|wc -c)))
  while [ "$spazi" -gt "0" ];do
   D4=$(echo " $D4")
   spazi=$(($spazi-1))
  done
  c=$(echo "$string"|tr " " "\n"|grep "C=")
  echo "-------------------------------"
  echo "$R1                   $R3"
  echo "$R2                   $R4"
  echo "-------------------------------"
  echo "$r1                   $r3"
  echo "$r2                   $r4"
  echo "-------------------------------"
  echo "D1=$D1                   D3=$D3"
  echo "D2=$D2                   D4=$D4"
  echo "-------------------------------"
  if [ "$D1" -le "$no" ]; then
   echo "1-NO                     "
  elif [ "$D1" -le "$weak" ]; then
   echo "1-WEAK                   "
  elif [ "$D1" -gt "$weak" ]; then
   echo "1-STRONG                 "
  fi
  if [ "$D3" -le "$no" ]; then
   echo "    3-NO"
  elif [ "$D3" -le "$weak" ]; then
   echo "  3-WEAK"
  elif [ "$D3" -gt "$weak" ]; then
   echo "3-STRONG"
  fi
  if [ "$D2" -le "$no" ]; then
   echo "2-NO                     "
  elif [ "$D2" -le "$weak" ]; then
   echo "2-WEAK                   "
  elif [ "$D2" -gt "$weak" ]; then
   echo "2-STRONG                 "
  fi
  if [ "$D4" -le "$no" ]; then
   echo "    4-NO"
  elif [ "$D4" -le "$weak" ]; then
   echo "  4-WEAK"
  elif [ "$D4" -gt "$weak" ]; then
   echo "4-STRONG"
  fi
 fi
 echo "$c - Press CTRL-C or Q to quit!"
 read -n1 -t 1 char
 if [ "$(echo "$char"|grep -i -c "q")" -gt "0" ]; then
  exit 0;
 else
  sleep 1
 fi
done
