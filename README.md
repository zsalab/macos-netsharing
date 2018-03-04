# macos-netsharing

Use this script to set up internet sharing for static IP assigned LAN network.

Note: MacOS built-in internet sharing starts DHCP server on the LAN interface and do not allow static addresses.

This script require root permission to execute, use sudo like: sudo macos-netsharing.sh ....

```
Usage: macos-netsharing.sh wan-dev lan-dev [start|stop]
	Examples:
		macos-netsharing.sh "Wi-Fi" "Apple USB Ethernet Adapter" start
		or
		macos-netsharing.sh en0 en6 start
```
