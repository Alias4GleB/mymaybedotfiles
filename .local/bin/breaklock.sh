#!/usr/bin/bash

DEBUG="${DEBUG:-0}"
#tmp files
TIMER_ENDTIME="${XDG_RUNTIME_DIR:-/tmp}/timer_endtime"
TIMER_NOW="${XDG_RUNTIME_DIR:-/tmp}/timer_now"
TIMER_ISWORKING="${XDG_RUNTIME_DIR:-/tmp}/timer_isworking"
TIMER_ISPOMODORO="${XDG_RUNTIME_DIR:-/tmp}/timer_ispomodoro"
TIMER_ISPAUSED="${XDG_RUNTIME_DIR:-/tmp}/timer_ispaused"
TIMER_ISFINISHED="${XDG_RUNTIME_DIR:-/tmp}/timer_isfinished"
TIMER_POMODORO="${XDG_RUNTIME_DIR:-/tmp}/timer_pomodoro"
#config
configpath="${XDG_CONFIG_HOME:-$HOME}/.pomodoroTimer"
configfile="${configpath}/pomodoroTimer.conf"

#global variables
declare -g duration defaulttimer defaultpomodoro defaultadd result_of_convert
# Configuration path check #defaults for pomodoro and normal + notification sound
configCreate()
{
    # create if it doesn't exist:
    if [[ ! -d "$configpath" ]]; then
	mkdir -p "$configpath"
	printf "\nCreated config path: %s\n" "$configpath"
    fi
    # same for config file
    if [[ ! -f "$configfile" ]]; then
	# touch "${configpath}/pomodoroTimer.conf"
	cat <<EOF> "$configfile"
##Default values

timer=5m
pomodoro=5m
add=5m

## password

password=

EOF
	printf "\nCreated configuration file at path: %s\n" "$configfile"
    fi
}

configWrite()
{
    configCreate
    # option print in config
    if [[ -n "$2" ]]; then
	local option value
	option="$1"
	value="$2"
	sed -i "s|^[[:space:]]*${option}=.*|${option}=${value}|" "$configfile"
	printf "Changed default number of %s to %s\n" "$option" "$value"
    fi

}

configRead()
{
    configCreate
    local key target_option value
    target_option="$1"
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
	[[ "$key" =~ ^# ]] && continue
	key="$(echo -n "$key" | xargs)"
	value="$(echo -n "$value" | xargs)"

	if [[ "$key" == "$target_option" ]]; then
	   printf "%s" "$value" 
	   return 0
	fi
	
    done < "$configfile"
}

debug()
{
    if (( DEBUG == 1 )); then
	printf "[DEBUG] %s\n" "$1"
    fi
}

isTimerWorking()
{
    debug "isTimerWorking()"
    if [[ -f "$TIMER_ISWORKING" ]]; then
       debug "isTimerWorking(): 1" 
       return 0
    else
	printf "Error: Aborted, timer is not in use. Try starting timer first\n" >&2
	exit 1
    fi
}

set_new_endtime()
{
    debug "$(printf "set_new_endtime()")"
    debug "$(printf "set_new_endtime(): duration is %s seconds\n" "$duration")"
    local now endtime
    printf -v now '%(%s)T' -1
    endtime=$((now + duration))
    echo "$endtime" > "$TIMER_ENDTIME"
    echo "$now" > "$TIMER_NOW"
    local isEndtime isNow
    [[ ! -f "$TIMER_ENDTIME" ]]; isEndtime=$?
    [[ ! -f "$TIMER_NOW" ]]; isNow=$?
    debug "$(printf "set_new_endtime(): isEndTime = %s" "$isEndtime")"
    debug "$(printf "set_new_endtime(): isNowTime = %s" "$isNow")"    
    debug "$(printf "set_new_endtime(): endtime = %d\n" "$endtime")"
    debug "$(printf "set_new_endtime(): now = %d\n" "$now")"
}

breaktime()
{
    debug "$(printf "breaktime(\)")"
    swaylock -i ~/screenlockpass/breaktime.jpg &
    local breaktime=$(< "$TIMER_POMODORO")
    sleep "$breaktime"
    debug "$(printf "breaktime(\): %d seconds passed, killing sway\n" "$breaktime")"
    pkill --signal SIGUSR1 swaylock
    debug "$(printf "breaktime(): successfully killed swaylock")"
    return 0
}

password_create()
{
    local PASS=$(configRead "password")

    echo $PASS > ~/screenlockpass/pass.txt

    return 0
}
    
do_timer()
{
    if [[ -z "$TIMER_ISWORKING" ]]; then
	exit 1
    fi
    debug "do_timer()"
    local current_endtime current_now breaktime
    current_endtime=$(< "$TIMER_ENDTIME")
    current_now=$(< "$TIMER_NOW")
    pomodoro=${0:-$(< "$TIMER_POMODORO")}
    #Countdown
    debug "do_timer(): countdown"
    debug "$(printf "do_timer(): current_endtime is %d\n" "$current_endtime")"
    debug "$(printf "do_timer(): current_now is %d\n" "$current_now")"
    debug "$(printf "do_timer(): length of pomodoro: %s\n" "$pomodoro")"
    # debug "$(printf "do_timer(): IsTimerWorking? %s" "$TIMER_ISWORKING")"
    # debug "$(printf "do_timer(): IsPOMODOROWorking? %s" "breaktime")"
    (
	while (( current_endtime > current_now )) && [[ -f "$TIMER_ISWORKING" ]] && [[ ! -f "$TIMER_ISPAUSED" ]] # 
	do
	    sleep 1
 	    (( current_now++ ))
	    debug "$(printf "changed current_now to %d\n" "$current_now")"
	    echo "$current_now" > "$TIMER_NOW"
	done

	# Pomodoro
	if [[ -f "$TIMER_ISPOMODORO" ]] && [[ ! -f "$TIMER_ISPAUSED" ]]; then
	    debug "POMODORO IS ON (FILE EXISTS)"
	    breaktime
	    set_new_endtime
	    do_timer
	fi
	
	# if timer has been unpaused,
	# it needs to reach the end to start again
	# ignore resetting timer in that case:
	# if pomodoro is on, ignore so it doesnt stop
	if [[ ! -f "$TIMER_ISPAUSED" ]] && [[ ! -f "$TIMER_ISPOMODORO" ]]; then
	    touch "$TIMER_ISFINISHED"
	    reset_timer
	fi
	
	return 0   

    )  &>/dev/null &
}

show_timer()
{
    debug "show_timer()"
    #do this if time needs to be shown once
    if [[ "$1" == "1" ]]; then
	# converting to 00:00:00
	current_now=$(< "$TIMER_NOW")
	current_endtime=$(< "$TIMER_ENDTIME")
	current_timer=$(( current_endtime - current_now ))
	hours=$(( current_timer / 3600 ))
	minutes=$(( current_timer % 3600 / 60 ))
	seconds=$(( current_timer % 60 ))

	if [[ ! -f "$TIMER_ISPAUSED" ]] && [[ -f "$TIMER_ISWORKING" ]]; then
	    printf "Time left: "
	fi
	
	printf "%02d:%02d:%02d\n" "$hours" "$minutes" "$seconds"
	return 0
    fi
	
    local input current_timer current_now current_endtime days hours minutes seconds isTimerFinished
    if [[ -f "$TIMER_ISPOMODORO" ]]; then
	local pomodoro pdays phours pminutes pseconds
    fi
    
    local didOnce=0
    
    while [[ "$input" != "q" ]];
    do
	[[ ! -f "$TIMER_ISFINISHED" ]]; isTimerFinished=$?
	debug "$(printf "isTimerFinished? %s" "$isTimerFinished")"
	# catch if timer finished its work in bg
	if [[ -f "$TIMER_ISFINISHED" ]]; then
	    printf "Timer is up!"
	    printf "\e[?25h\n"
	    rm -f "$TIMER_ISFINISHED"
	    exit 0
	fi

	if (( didOnce == 0 )); then
	    isTimerWorking
	    printf "\e[?25l"
	    printf "\n"
	    didOnce=1
	fi
	
	# converting to 00:00:00
	current_now=$(< "$TIMER_NOW")
	current_endtime=$(< "$TIMER_ENDTIME")
	current_timer=$(( current_endtime - current_now ))
	days=$(( currenttimer / 86400 ))
	hours=$(( current_timer / 3600 ))
	minutes=$(( current_timer % 3600 / 60 ))
	seconds=$(( current_timer % 60 ))

	printf "\e[1A"

	printf "\rTime left: %03d:%02d:%02d:%02d  " "$days" "$hours" "$minutes" "$seconds"
	if [[ -f "$TIMER_ISPOMODORO" ]]; then
	    pomodoro=$(< "$TIMER_POMODORO")
	    pdays=$(( pomodoro / 86400 ))
	    phours=$(( pomodoro / 3600 ))
	    pminutes=$(( pomodoro % 3600 / 60 ))
	    pseconds=$(( pomodoro % 60 ))
	    printf "Set Pomodoro length: %03d:%02d:%02d:%02d\n" "$pdays" "$phours" "$pminutes" "$pseconds"
	fi
	printf "Press [q] to stop showing. \e[K" #maybe add s - stop, p - pause, r - reset 
	read -s -n 1 -t 1 input
    done
    printf "\e[?25h\n"
    rm -f "$TIMER_ISFINISHED"
    return 0
}

reset_timer()
{
    debug "reset_timer()"
    
    rm -f "$TIMER_ISWORKING"
    rm -f "$TIMER_NOW"
    rm -f "$TIMER_ENDTIME"
    rm -f "$TIMER_ISPOMODORO"
    rm -f "$TIMER_ISPAUSED"
    rm -f "$TIMER_POMODORO"
    
    printf "Timer has been resetted\n"
    
    exit 0
}

pause_timer_switch()
{
    debug "pause_timer_switch()"
    isTimerWorking
    
    local isPaused 
    local once="1"

    [[ -f "$TIMER_ISPAUSED" ]]; isPaused=$?
    debug "$(printf "isPaused = %d" "$isPaused")"
    
    case "$isPaused" in
	1)
	    touch "$TIMER_ISPAUSED"
	    printf "Paused timer at "
	    show_timer "$once"
	    exit 0 ;;
	0)
	    rm -f "$TIMER_ISPAUSED"
	    printf "Unpaused timer\n"
	    show_timer "$once"
	    do_timer
	    exit 0 ;;
    esac
}
    
convertsmhtosec()
{
    debug "convertsmhtosec()"
    
    local regexed="$1"
    debug "$(printf "convertsmhtosec(): %s\n" "$regexed")" 
    local number="${regexed%[smh]}"
    local letter_multiplier="${regexed#$number}"

    #if its only number, dont convert and end the function
    if [ -z "$letter_multiplier" ]; then
	debug "convertsmhtosec(): its only number"
	result_of_convert="$number"
       return 0
    fi
    
    #converting to seconds
    debug "convertsmhtosec(): converting normally..."
    case "$letter_multiplier" in
	s) letter_multiplier=1 ;;
	m) letter_multiplier=60 ;;
	h) letter_multiplier=3600 ;;
	d) letter_multiplies=86400 ;;
	#if letter is longer than one
	*) printf "Error: Unknown time format %s\n" "$letter_multiplier"; exit 1 ;;
    esac

    #seconds result
    result_of_convert=$(( letter_multiplier * number ))
    debug "$(printf "convertsmhtosec(): converted %s seconds\n" "$result_of_convert")"
    return 0
}

add2timer()
{
    debug "add2timer()"
    isTimerWorking
    local added="$1"
    convertsmhtosec "$1"
    local addition="$result_of_convert"
    local endtime=$(< "$TIMER_ENDTIME")
    debug "$(printf "add2timer(): endtime before the addition: %d\n" "$endtime")"
    endtime=$(( endtime + addition ))
    debug "$(printf "add2timer(): endtime after the addition: %d\n" "$endtime")"
    echo "$endtime" > "$TIMER_ENDTIME"
    printf "Successfully added %d seconds to the timer\n" "$addition"
    show_timer "1"
    return 0
}

printManual()
{
    printf "\n"
    printf "PomodoroTimer\n"
    printf "\n"
    printf "Commands:\n"
    printf '%s\n' "--- s|start - starts a timer"
    printf '%s\n' "--- show|status - shows current state of timer"
    printf '%s\n' "--- r|reset - stops and resets state of timer"
    printf '%s\n' "--- p|pause - pauses the timer"
    printf '%s\n' "--- a|add - adds time to the timer"
    printf '%s\n' "--- set - sets value for the key to configuration file"
    printf '%s\n' "--- set is used with either [password] or [default]"
    printf '%s\n' "--- Password is the one used for unlock in swaylock (for more info: \"$0 set password --help\""
    printf '%s\n' "--- Defaults are fallbacks if user doesnt put anything as a value"
    printf "(e.g. \"$0 start\" \"$0 start -p\")\n"
    printf '%s\n' "--- Available defaults: timer, pomodoro, add"
    printf "\n"
    printf "Flags:\n"
    printf "for [start]:\n"
    printf '%s\n' "   -p|--pomodoro - activate pomodoro mode and set lenght of the time break"
    printf "\n"
    printf "Values for timer (and pomodoro):\n"
    printf "'d' - days; 'h' - hours; 'm' - minutes; 's' seconds (default if value has no letter)\n"
    printf "Examples: 10d; 3h; 50m; 30\n"
    printf "\n"
    printf "made by Alias4G\n"
    printf "\n"

    exit 0
}

printHelpPassword()
{
    exit 0
}


password_create

case "$1" in
    s|start) #start
	# catch if timer alreadly working abort
	debug "start"
	
	if [[ -f "$TIMER_ISWORKING" ]]; then
	    printf "Error: Timer is already working!\n"
	    exit 1
	fi
	shift 1
	while [ $# -gt 0 ]
	do
	    debug "Im in while now"
	    case "$1" in
		#if $1 is a -p flag 
		--pomodoro|-p)
		    debug "Case is --pomodoro|p"
		    # defaulting to config value if there is nothing after -p flag
		    if [[ -z "$2" ]]; then
			touch "$TIMER_ISPOMODORO"
			defaultpomodoro="$(configRead "pomodoro")"
			printf "No pomodoro break duration value detected, using default (%s)\n" "$defaultpomodoro"
			convertsmhtosec "$defaultpomodoro"
			echo "$result_of_convert" > "$TIMER_POMODORO"
			leavethecase=1
		    #catch if value after -p is not a proper number
		    elif [[ "$2" == -* ]] || [[ ! "$2" =~ ^[0-9]+[smhd]?$ ]]
		    then
			printf "Error: option %s requires a proper value [10|5m|10h|1d]\n" "$1" >&2
			exit 1
		    elif (( leavethecase != 1 )); then #if $2 is a proper number
		    touch "$TIMER_ISPOMODORO"
		    
		    convertsmhtosec "$2"
		    
		    echo "$result_of_convert" > "$TIMER_POMODORO"
		    shift 1
		    fi
		    ;;
		#if user types something like --ssdfg or -ssdfg or -100h or -1 instead of proper flag of number for timer
		-*)
		    debug "Case is -*"
		    printf "Unknown flag %s for 'start' command\n" "$1" >&2
		    exit 1 ;;
	        #if user types unknown command or a number for timer
		*)
		    debug "Case is *"
		    #error if its something like "rstdsrtd" or 10l
		    if [[ ! "$1" =~ ^[0-9]+[smhd]?$ ]]
		    then
			printf "Error: Unknown command %s\n" "$1" >&2
			exit 1
		    fi
		    #if its a number (for a timer value)
		    convertsmhtosec "$1"
		    duration="$result_of_convert"
		    
		    ;;
	    esac
	    shift 1
	    debug "Im out of case"
	done

	touch "$TIMER_ISWORKING"
	rm -f "$TIMER_ISFINISHED"
	if [[ -z "$duration" ]]; then
	    defaulttimer="$(configRead "timer")"
	    printf "No timer duration value detected, going default (%s)\n" "$defaulttimer"
	    convertsmhtosec "$defaulttimer"
	    duration="$result_of_convert"
	fi
	
	set_new_endtime
	do_timer
	show_timer ;;
    
    show|status) show_timer ;;
    r|reset) reset_timer ;;
    p|pause) pause_timer_switch ;;
    a|add)
	# defaulting to config value if empty
	if [[ -z "$2" ]]; then
	    defaultadd="$(configRead "$1")"
	    printf "No add value detected, using default (%s)\n" "$defaultadd"
	    convertsmhtosec "$defaultadd"
	    add2timer "$result_of_convert"
	#catch if text after add is not a proper number
	elif [[ ! "$2" =~ ^[0-9]+[smhd]?$ ]]; then
	    printf "Error: command %s requires a value [10s|5m|10h|1d]\n" "$1" >&2
	    exit 1
	    echo "$result_of_convert" > "$TIMER_POMODORO"
	else #if its a proper number
	    convertsmhtosec "$2"
	    add2timer "$result_of_convert"
	    exit 0
	fi
	;; #end of add command
    set)
	shift
	case "$1" in
	    default)
		shift
		case "$1" in
		    timer) # change timer default
			if [[ -z "$2" ]]; then
			    printf "Error: option %s requires a value\n" "$1" >&2
			    exit 1
			fi
			
			configWrite "$1" "$2"
			exit 0 ;;
		    
                    pomodoro) # change pomodoro break default
			if [[ -z "$2" ]]; then
			    printf "Error: option %s requires a value\n" "$1"
			    exit 1
			fi
			
			configWrite "$1" "$2"
			exit 0   ;;
		    add) # change add default
			if [[ -z "$2" ]]; then
			    printf "Error: option %s requires a value\n" "$1"
			    exit 1
			fi

			configWrite "$1" "$2"
			exit 0 ;;
		    show) # show default numbers
			configCreate()
			defaulttimer=$(< configRead "timer")
			defaultadd=$(< configRead "add")
			defaultpomodoro=$(< configRead "pomodoro")
			printf "Default numbers: timer - \"%s\", pomodoro - \"%s\", add - \"%s\"\n"
			exit 0 ;;
		    *)
			printf "Error: command 'set default' requires an option: [timer|pomodoro|show]\n"
			exit 1 ;;
		esac
		;; #end of default)
	    --help) printHelpPassword ;;
	    *)
		printf "$0: Error: command 'set' requires an option: [default|password]\n"
		exit 1 ;;
	esac
	;; #end of set command
    --help) printManual ;;
		    
    *) printf "$0: Unknown command '$1'\nUse \"--help\" for manual\n" >&2
       exit 1 ;; #end of all commands
esac

exit 0
