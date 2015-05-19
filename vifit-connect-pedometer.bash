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

function setTime { # {{{
	time="01$(date "+%y%m%d%H%M%S")0000000000000000"
	time="${time}$(getCkSum "${time}")"
	./vifit-connect-pedometer-write-data.expect "${time}" "Characteristic value was written successfully"
}
# }}}
function setStepGoal { #{{{
	goal="${1}"
	goalHex="${D2H[$((${goal}%256))]}"
	goalHex="${D2H[$((${goal}/256))]}${goalHex}"
	goalHex="0b00${goalHex}00000000000000000000000"
	goalHex="${goalHex}$(getCkSum "${goalHex}")"
	./vifit-connect-pedometer-write-data.expect "${goalHex}" "Characteristic value was written successfully"
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
	./vifit-connect-pedometer-write-data.expect "${personalData}" "Characteristic value was written successfully"
}
# }}}

while getopts ':pts:h' OPTION ; do
	case ${OPTION} in
		h)	usage ${EXIT_SUCCESS}
			;;
		p) SETPERSONAL="y"
			;;
		s) SETSTEPGOAL="${OPTARG//[^0-9]/}"
			;;
		t) SETTIME="y"
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

[ "${SETTIME}" == "y" ] && setTime
[ -n "${SETSTEPGOAL}" -a "${SETSTEPGOAL}" != "0" ] && setTime
[ "${SETPERSONAL}" == "y" ] && setPersonalData

exit ${EXIT_SUCCESS}
