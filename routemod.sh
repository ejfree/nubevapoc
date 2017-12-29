#!/bin/sh

#Modify routing on peer to support Internet connectivity
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo ip route add 10.10.0.0/16 via 10.11.1.1
