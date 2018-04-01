#!/bin/sh

dns=$1
sleep_time=30
ttl=0

if [ "$dns" == "" ]; then
	echo Usage: $0 DNS_SERVER
	exit
fi

function ttl_action {
	if [ "$1" == "D" ]; then
		if [ "$2" == "0" ]; then
			return 0
		fi
	fi
	echo iptable action: $1, ttl: $2
	iptables -$1 INPUT -s $dns -m ttl ! --ttl-eq $2 -j DROP
}

function cleanup {
	echo cleanup..
	ttl_action D $ttl
}

function interrupt {
	exit
}

trap interrupt INT
trap cleanup EXIT

while true; do
	new_ttl=`ping -c 1 $dns | grep ttl= | sed -E  's/.*ttl=(\d+).*/\1/'`
	if [ "$ttl" != "$new_ttl" ]; then
		echo update iptables
		ttl_action D $ttl
		ttl=$new_ttl
		ttl_action I $ttl
	else
		echo ttl has no update
	fi
	sleep $sleep_time
done
