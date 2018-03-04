#! /bin/sh

if [ `whoami` != 'root' ]; then
	echo 'This script require superuser permission, execute with sudo' >&2
	exit 140
fi

if [ "$1" = '-h' ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ `echo "$3" | grep -c -E '^(start|stop)$'` -eq 0 ]; then
	scriptname="$(basename $0)"
	echo "Usage: $scriptname wan-dev lan-dev [start|stop]"
	echo '	Examples:'
	echo "		$scriptname \"Wi-Fi\" \"Apple USB Ethernet Adapter\" start"
	echo '		or'
	echo "		$scriptname en0 en6 start"
	exit 131
fi

wan=`networksetup -listallhardwareports | grep -A 1 -E "^(Hardware Port|Device): $1$" | grep '^Device:' | sed 's/^Device: //'`
if [ -z "$wan" ]; then
	echo "WAN device not found with name $1" >&2
	exit 132
fi
lan=`networksetup -listallhardwareports | grep -A 1 -E "^(Hardware Port|Device): $2$" | grep '^Device:' | sed 's/^Device: //'`
if [ -z "$lan" ]; then
	echo "LAN device not found with name $2" >&2
	exit 133
fi
if [ `ifconfig "$lan" | grep -c -E '[[:space:]]+inet '` -eq 0 ]; then
	echo "No IP assigned to LAN device: $2" >&2
	exit 134
fi

function restartpf {
	pfctl -n -f /etc/pf.conf
	ec=$?
	if [ $ec -eq 0 ]; then
		pfctl -d
		pfctl -E -f /etc/pf.conf
		ec=$?
		if [ $ec -ne 0 ]; then
			echo 'FAILED' >&2
		else
			echo 'OK'
		fi
	else
		echo 'FAILED' >&2
	fi
	return $ec
}

function start {
	echo "Configuring internet sharing: $lan -> $wan"
	if [ `grep -c "nat on $wan from $lan:network to any -> ($wan)" /etc/pf.conf` -eq 0 ]; then
		echo "nat on $wan from $lan:network to any -> ($wan)" >> /etc/pf.conf
	fi
	sysctl -w net.inet.ip.forwarding=1
	restartpf
	return $?
}

function stop {
	echo "Unconfiguring internet sharing: $lan -> $wan"
	if [ `grep -c "nat on $wan from $lan:network to any -> ($wan)" /etc/pf.conf` -gt 0 ]; then
		sed -i .bak "/nat on $wan from $lan:network to any -> ($wan)/d" /etc/pf.conf
		rm /etc/pf.conf.bak
	fi
	if [ `grep -c '^nat ' /etc/pf.conf` -eq 0 ]; then
		sysctl -w net.inet.ip.forwarding=0
	fi
	restartpf
	return $?
}

if [ "$3" = 'start' ]; then
	start
	ec=$?
	if [ $ec -ne 0 ]; then
		stop
	fi
	exit $ec
else
	stop
	exit $?
fi
