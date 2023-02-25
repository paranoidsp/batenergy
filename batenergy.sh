#!/usr/bin/env bash

FILE=/tmp/batenergy.dat

state=$1
sleep_type=$2

now=`date +'%s'`

read energy_now0 < /sys/class/power_supply/BAT0/energy_now #μWh
read energy_full0 < /sys/class/power_supply/BAT0/energy_full # μWh
read energy_now1 < /sys/class/power_supply/BAT1/energy_now #μWh
read energy_full1 < /sys/class/power_supply/BAT1/energy_full # μWh
read online < /sys/class/power_supply/AC/online
total_energy_full=$((($energy_full0 + $energy_full1)))


(($online)) && echo "Currently on mains."
((! $online)) && echo "Currently on battery."

case $state in
"pre")
	echo "Saving time and battery energy before sleeping ($sleep_type)."
	echo $now > $FILE
	echo $energy_now0 >> $FILE
	echo $energy_now1 >> $FILE
	;;
"post")
	exec 3<>$FILE
	read prev <&3
	read energy_prev0 <&3
	read energy_prev1 <&3
	rm $FILE
	time_diff=$(($now - $prev)) # seconds
	days=$(($time_diff / (3600*24)))
	hours=$(($time_diff % (3600*24) / 3600))
	minutes=$(($time_diff % 3600 / 60))
	echo "Duration of $days days $hours hours $minutes minutes sleeping ($sleep_type)."
	energy_diff0=$((($energy_now0 - $energy_prev0) / 1000)) # mWh
	energy_diff1=$((($energy_now1 - $energy_prev1) / 1000)) # mWh
  total_energy_diff=$((($energy_diff0 + $energy_diff1)))
	avg_rate=$(($total_energy_diff * 3600 / $time_diff)) # mW
	total_energy_diff_pct=$(bc <<< "scale=1;$total_energy_diff * 100 / ($total_energy_full / 1000)") # %
	avg_rate_pct=$(bc <<< "scale=2;$avg_rate * 100 / ($total_energy_full / 1000)") # %/h
	echo "Battery energy change of $total_energy_diff_pct % ($total_energy_diff mWh) at an average rate of $avg_rate_pct %/h ($avg_rate mW)."
	;;
esac
