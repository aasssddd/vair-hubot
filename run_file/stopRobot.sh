#!/bin/bash

PID="$(cat hubot.pid)"
DATE="$(date +%Y-%m-%d_%H-%M)"
echo $PID
kill -9 $PID
rm -rf hubot.pid
mv ./logs/hubot.log "./logs/hubot.log.$DATE"
echo log is archive to hubot.log.$DATE
echo "Robot is stopped"
