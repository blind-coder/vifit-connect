#!/bin/bash

tmp="$(mktemp)"
tmp2="$(mktemp)"
trap "rm -f '${tmp}' '${tmp2}'" EXIT

for log in "${@}"; do
	first=y
	sum=0
	echo -n > "${tmp}"
	echo -n > "${tmp2}"
	while read idx time step rest; do
		[ "${step}" == 0 -a "${first}" == "y" ] && continue
		first=n
		sum=$((${sum}+${step}))
		echo "${idx} ${time} ${step} ${sum}" >> "${tmp2}"
		if [ ${step} -gt 0 ]; then
			cat "${tmp2}" >> "${tmp}"
			echo -n > "${tmp2}"
		fi
	done < "${log}"
	gnuplot -e "filename='${tmp}'" $(which plotData.gp) > "${log%log}png"
done
