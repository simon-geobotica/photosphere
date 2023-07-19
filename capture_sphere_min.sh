#!/bin/bash

TMPDIR="~/Pictures/temp"

# wake camera, normally asleep so required
ptpcam --set-property=0xD80E --val=0x00 >> /dev/null
# No auto power off
ptpcam --set-property=0xD81B --val=0x00
# No auto sleep
ptpcam --set-property=0xD803 --val=0x00

while true
do
    # wake camera, normally asleep so required
    ptpcam --set-property=0xD80E --val=0x00 >> /dev/null
    sleep 10

    up=`ptpcam -i | grep "THETA" | wc -l`

    # check the battery status
    battery=`ptpcam --show-property=0x5001 | grep "to:" | awk '{print $6}'`

    # set working directory
    # in which to save the data
    cd $TMPDIR

    sunrise=$(date -d "04:00 Today" +'%s')
    sunset=$(date -d "17:00 Today" +'%s')

    # get current time in unix time seconds
    now=$(date +'%s')
    
    # set night mode based upon the seconds of day
    if  [ $now -le $sunset ] && [ $now -ge $sunrise ];
    then
	    nightmode="false"
    else
        nightmode="true"
    fi

    echo "Night mode: $nightmode"

    ptpcam --set-property=0x500E --val=0x8003 # ISO priority (set to 0x0002 for auto)
    ptpcam --set-property=0x5005 --val=0x8002 # set WB to cloudy
    # Could also try 0x0004 (Outdoor) or 0x8001 (Shade)

    # Full list of ISO options: [80, 100, 125, 160, 200, 250, 320, 400, 500, 640, 800, 1000, 1250, 1600, 2000, 2500, 3200, 4000, 5000, 6400]
    if [[ "$nightmode" == "false" ]]
    then
        ptpcam --set-property=0x500F --val=200 # set ISO
    else
        ptpcam --set-property=0x500F --val=640 # set ISO
    fi

    #capture image
    ptpcam -c

    echo "Sleeping to wait for camera to finish processing image"
    sleep 10

    echo "Transferring image from camera"
    gphoto2 -P
    gphoto2 -f /store_00020001/DCIM/100RICOH -D

    cd ../log
    # output battery status to file
    echo "" >> battery_status.txt
    date >> battery_status.txt
    echo $sunset >> battery_status.txt
    echo "Battery: $battery%" >> battery_status.txt
    #echo $nightmode >> battery_status.txt

    sleep 5

done

# done
exit 0
