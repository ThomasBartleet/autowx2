#!/bin/bash

# We want to easily find the program (if it is running) and kill it. The safest
# way to automate this is to find the PID of the running program and kill it.
# To get the PID use the `pidof` command. Because the parent processor of this
# program is Python, we will use `pidof python` and kill all Python-related
# programs (only one should be running anyway).

pids=$(pidof python)
if [ "$pids" == "" ]; then
    # No PIDs found, therefore no Python programs running. Just exit.
    echo "No Python programs running."
    exit 0
fi

pidArray=( $pids )
for pid in $pidArray
do
    # Kill the process, by send a "kill signal" to the process.
    kill -SIGKILL $pid
done

# Ensure the process(es) not longer exists
pids=$(pidof python)
if [ "$pids" != "" ]; then
    # PIDs were still found, therefore some Python program is still running.
    # Send a message to the console to notify the user.
    echo "There is still at least one Python program running: $pids"
fi

# Finish.