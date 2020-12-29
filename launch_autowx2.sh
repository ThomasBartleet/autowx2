#!/bin/bash

# Whilst this process seems to highly simplify the process of checking of the
# program is running, do read up on this: https://stackoverflow.com/a/697064/3872145
# This may be the laziest and simplest way, but it might not be the best
# solution. https://stackoverflow.com/a/2366718
if ps -ef | grep -v grep | grep "autowx2.py" ;
then
    # Do nothing. The process is already running.
    exit 0
else
    cd /home/pi/autowx2/
    $(MPLBACKEND=Agg python autowx2.py) & # & makes it run in the background.
fi


# NOTE:
# Run this in `crontab` every day. It doesn't matter what time, but once a
# day should cover it.