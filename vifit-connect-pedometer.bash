#!/bin/bash
# Script:	vifit-connect-pedometer.bash
# Task:	Interacting with a MediSana ViFit Connect pedometer via BT LE

[ -z "${BASH}" ] && exec bash "${0}" "${@}"

# global variables
SCRIPTNAME=$(basename ${0} .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

DAYS="43000000000000000000000000000043 43010000000000000000000000000044 43020000000000000000000000000045 43030000000000000000000000000046 43040000000000000000000000000047 43050000000000000000000000000048 43060000000000000000000000000049 4307000000000000000000000000004a 4308000000000000000000000000004b 4309000000000000000000000000004c 430a000000000000000000000000004d 430b000000000000000000000000004e 430c000000000000000000000000004f 430d0000000000000000000000000050 430e0000000000000000000000000051"

# variables for option switches with default values
VERBOSE="n"
OPTFILE=""
SETTIME="n"
SETSTEPGOAL="0"
SETPERSONAL="n"
READSTEPS="n"

# functions
D2H=({{0..9},{A..F}}{{0..9},{A..F}})
hex2dec () # {{{
{ 
	echo -n "$((16#${1}))";
}
# }}}
function getCkSum { # {{{
	sum=0
	par="${1}"
	while [ -n "${par}" ]; do
		sum=$((${sum} + $( hex2dec "${par:0:2}" )))
		par="${par:2}"
	done
	sum=$((${sum}%256))
	sum=${D2H[${sum}]}
	echo "${sum}"
}
# }}}
function usage { # {{{
	echo "Usage: ${SCRIPTNAME} [-h] [-v] [-o arg] file ..." >&2
	[[ ${#} -eq 1 ]] && exit ${1} || exit ${EXIT_FAILURE}
}
# }}}
function verbose { #{{{
	if [ "${VERBOSE}" == "n" ]; then
		return
	fi
	echo "${@}"
}
# }}}

function setTime { # {{{
	time="01$(date "+%y%m%d%H%M%S")0000000000000000"
	time="${time}$(getCkSum "${time}")"
	verbose "Setting time to ${time:2:12}"
	vifit-connect-pedometer-write-data.expect "${time}" "Characteristic value was written successfully"
}
# }}}
function setStepGoal { #{{{
	goal="${1}"
	goalHex="${D2H[$((${goal}%256))]}"
	goalHex="${D2H[$((${goal}/256))]}${goalHex}"
	goalHex="0b00${goalHex}00000000000000000000000"
	goalHex="${goalHex}$(getCkSum "${goalHex}")"
	verbose "Setting stepgoal to ${goal}"
	vifit-connect-pedometer-write-data.expect "${goalHex}" "Characteristic value was written successfully"
}
#}}}
function setPersonalData { # {{{
	read -p "Please enter your age in years> " ageInYears
	read -p "Please enter your height in centimeters (cm)> " heightInCM
	read -p "Please enter your weight in kilograms (kg)> " weightInKG
	read -p "Please enter your steplength in centimeters (cm)> " stepLengthInCM
	ageInYears=${D2H[${ageInYears}]}
	heightInCM=${D2H[${heightInCM}]}
	weightInKG=${D2H[${weightInKG}]}
	stepLengthInCM=${D2H[${stepLengthInCM}]}
	personalData="0201${ageInYears}${heightInCM}${weightInKG}${stepLengthInCM}000000000000000000"
	personalData="${personalData}$(getCkSum "${personalData}")"
	verbose "Setting personal data"
	vifit-connect-pedometer-write-data.expect "${personalData}" "Characteristic value was written successfully"
}
# }}}
function readSteps { # {{{
	tmp="$(mktemp)"
	for day in ${DAYS}; do
		verbose "Reading pedometer data from $(date -d "-${day:2:2} day" +%Y-%m-%d)"
		vifit-connect-pedometer-write-data.expect "${day}" "Notification handle = 0x0038 value: 43 f0 .. .. .. 5f" > "${tmp}"
		if [ $( grep -c '0x0038 value: 43' "${tmp}" ) -lt 5 ]; then
			verbose "No more records"
			rm -f "${tmp}"
			return
		fi

		while read yy mm dd idx type lsb msb; do
			echo "$yy $mm $dd $idx $type $lsb $msb" > /dev/null
			[ "${idx}" == "00" ] && echo -n > "20${yy}-${mm}-${dd}.log"
			if [ "${type,,}" == "ff" ]; then
				continue
			fi
			read t < <( hex2dec "${idx}" )
			read steps < <( hex2dec "${msb}${lsb}" )
			printf "%d %02d:%02d %s\n" ${t} $((${t}/4)) $((${t}%4*15)) "${steps}" >> "20${yy}-${mm}-${dd}.log"
		done < <( grep -o '0x0038 value: 43.*$' "${tmp}" | cut -f05-7,8-9,12-13 -d' ' )
	done
	rm -f "${tmp}"
}
# }}}

while getopts ':rpts:hv' OPTION ; do
	case ${OPTION} in
		h)	usage ${EXIT_SUCCESS}
			;;
		v) VERBOSE="y"
			;;
		p) SETPERSONAL="y"
			;;
		s) SETSTEPGOAL="${OPTARG//[^0-9]/}"
			;;
		t) SETTIME="y"
			;;
		r) READSTEPS="y"
			;;
		\?)	echo "unknown option \"-${OPTARG}\"." >&2
			usage ${EXIT_ERROR}
			;;
		:)	echo "option \"-${OPTARG}\" requires an argument." >&2
			usage ${EXIT_ERROR}
			;;
		*)	echo "Impossible error. parameter: ${OPTION}" >&2
			usage ${EXIT_BUG}
			;;
	esac
done

if ! hash "vifit-connect-pedometer-write-data.expect" > /dev/null; then
	export PATH=.:${PATH}
	if ! hash "vifit-connect-pedometer-write-data.expect" > /dev/null; then
		echo "Cannot find vifit-connect-pedometer-write-data.expect in PATH!" >&2
		exit ${EXIT_FAILURE}
	fi
fi
verbose "Found vifit-connect-pedometer-write-data.expect at $(which "vifit-connect-pedometer-write-data.expect")"

[ "${SETTIME}" == "y" ] && setTime
[ -n "${SETSTEPGOAL}" -a "${SETSTEPGOAL}" != "0" ] && setTime
[ "${SETPERSONAL}" == "y" ] && setPersonalData
[ "${READSTEPS}" == "y" ] && readSteps

exit ${EXIT_SUCCESS}
