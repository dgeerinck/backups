#!/bin/bash
#
# Perform a backup if a certain amount of time has passed.
#
# This script performs a backup of a user-specified directory using a
# user-specified backup command. If the backup command exits successfully (with
# an exit code of zero) the current timestamp is saved in a file. Every time
# the script runs, it checks the timestamp stored in the file. If the timestamp
# is greater than a user-specified period, the backup command is executed.
#
# I want to perform daily, remote backups on a laptop. I only want the backup
# to attempt to execute if I am logged in and online, so I don't want to run it
# as a normal cron job. Further, the backup is of a filesystem. I only want the
# backup to execute if the filesystem is mounted.
#
# The idea is that this script could be called every time you login. Even if
# you login numerous times per day, backups will only be executed once per day
# (assuming that the period you specified was one day). If you use a network
# manager, such as wicd, you could have this script execute every time you
# connect to a network. Again, backups will only be executed once per period,
# even if you connect to the network more frequently.
#
#
# Hey yo but wait, back it up, hup, easy back it up
#
#
# Author:   Pig Monkey (pm@pig-monkey.com)
# Website:  https://github.com/pigmonkey/backups
#
###############################################################################
verbosity=0
v=1; vv=2; vvv=3;
doLog(){
	[ -z "$1" ] && { echo "$0 doLog(msg, level): message not specified"; return;}
	msgStr=$1; 		#1str param is message
	msgLevel=${2:-$v}; 	#2nd  param is message level
	#echo "(level:$msgLevel, \"$msgStr\")";
	if [ $msgLevel -le $verbosity ]; then echo "BackItUp_Msg($msgLevel): $msgStr"; fi
}


# Define the backup command.
BACKUP="echo Error : No backup command provided!"

# Define the file that will hold the timestamp of the last successful backup.
# It is recommended that this file be *inside* the directory to be backed up.
LASTRUN="./lastrun"

# Define the command to be executed if the file which holds the time of the
# previous backup does not exist. The default behaviour here is to simply
# create the file, which will then cause the backup to be executed. If the
# directory you specified above is a mount point, the file not existing may
# indicate that the filesystem is not mounted. In that case, you would place
# your mount command in this string. If you want the script to exit when the
# file does not exist, simply set this to a blank string.
NOFILE="touch $LASTRUN"

# Define the period, in seconds, for backups to attempt to execute.
# Hourly:   3600
# Daily:    86400
# Weekly:   604800
# The period may also be set to the string 'DAILY', 'WEEKLY' or 'MONTHLY'.
# Note that this will result in behaviour that is different from setting the
# period to the equivalent seconds.
PERIOD='DAILY'

# End configuration here.
###############################################################################

usage() {
    echo "Usage: backitup.sh [OPTION...]
Note that any command line arguments overwrite variables defined in the source.

Options:
    -vvv    verbosity
    -p      the period for which backups should attempt to be executed
            (integer seconds or 'DAILY', 'WEEKLY' or 'MONTHLY')
    -b      the backup command to execute; note that this should be quoted if it contains a space
    -l      the location of the file that holds the timestamp of the last successful backup.
    -n      the command to be executed if the above file does not exist"
}


backup() {
    # Execute the backup.
    doLog '[+]Executing backup()...' $vvv
    $BACKUP | while read -r line; do doLog "Bkup : $line" $v; done  
    # If the backup was succesful, store the current time.
    if [ $? -eq 0 ]; then
        doLog 'Backup completed.' $vv
        date $timeformat > "$LASTRUN"
        doLog "Write `date $timeformat` in LastRun file $LASTRUN" $vv
    else
        doLog "Error : Backup script '$BACKUP' FAILED" $vv
    fi
    exit
}

# Get any arguments.
doLog '[+]Get any arguments' $vvv
while getopts "v :p:b:l:n:h" opt; do
    case $opt in
    	v)
	    verbosity=$(($verbosity+1))
    	    ;;
        p)
            [ -z "$OPTARG" ] && { doLog 'Error: Invalid Period!' 0; usage; exit; } 
            PERIOD=$OPTARG
            ;;
        b)
            [ -z "$OPTARG" ] && { doLog 'Error: Backup command!' 0; usage; exit; } 
            BACKUP=$OPTARG
            ;;
        l)
            LASTRUN=$OPTARG
            ;;
        n)
            NOFILE=$OPTARG
            ;;
        h)
            usage
            exit
            ;;
        :)
            echo "Option -$OPTARG requires an argument.
            "
            usage
            exit
            ;;
    esac
done

# Set the format of the time string to store.
if [ "$PERIOD" = 'DAILY' ]; then
    timeformat='+%Y%m%d'
elif [ "$PERIOD" = 'WEEKLY' ]; then
    timeformat='+%G-W%W'
elif [ "$PERIOD" = 'MONTHLY' ]; then
    timeformat='+%Y%m'
else
    timeformat='+%s'
fi

doLog "[+] Params :  " $vvv
doLog "  PERIOD=$PERIOD (timeformat = $timeformat)" $vvv
doLog "  BACKUP=$BACKUP" $vvv
doLog "  LASTRUN=$LASTRUN" $vvv
doLog "  NOFILE=$NOFILE" $vvv



# If the file does not exist, perform the user requested action. If no action
# was specified, exit.
doLog "[+]Check if $LASTRUN file exists and not empty..." $vv
if [ ! -e "$LASTRUN" ]; then
    if [ -n "$NOFILE" ]; then
	NOFILE="touch $LASTRUN"
        $NOFILE
    else
        exit
    fi
else 
    doLog '  LastRun file found and not empty' $vv
fi

# If the file exists and is not empty, get the timestamp contained within it.
if [ -s "$LASTRUN" ]; then
    timestampBkup=$(eval cat \$LASTRUN); 
    timestampNow=`date $timeformat`;	 

    # If the backup period is daily, weekly or monthly, perform the backup if
    # the stored timestamp is not equal to the current date in the same format.
    if [ "$PERIOD" = 'DAILY' -o "$PERIOD" = 'WEEKLY' -o "$PERIOD" = 'MONTHLY' ]; then
	doLog "$timestampBkup = Period Last Bkup" $vvv; 
	doLog "$timestampNow = Period Now" $vvv
        if [ $timestampBkup != $timestampNow ]; then
            backup
        else
            doLog "Right now (@$timestampNow), last $PERIOD backup (@$timestampBkup) is OK. Exiting." $vv
            exit
        fi

    # If the backup period is not daily, perform the backup if the difference
    # between the stored timestamp and the current time is greater than the
    # defined period.
    else
        doLog "$timestampBkup = timestamp Last Bkup" $vvv; 
	doLog "$timestampNow = timestamp Now" $vvv
        diff=$(( $timestampNow - $timestampBkup))
        if [ "$diff" -gt "$PERIOD" ]; then
            backup
        else
            doLog "Last backup (timestamp=$timestampBkup) less than $PERIOD seconds ago. Exiting." $vv
            exit
        fi
    fi
fi

# If the file exists but is empty, the script has never been run before.
# Execute the backup.
if [ -e "$LASTRUN" ]; then
    backup
fi

