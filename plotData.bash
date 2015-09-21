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
	gnuplot > "${log%log}png" <<EOF
set terminal png size 1280, 768 font "Times,12"
set boxwidth 0.5
set style fill solid
set key off
set title "${log%.log}"

set xtics rotate by 270
set yrange [0:*]
set ylabel "Steps"

set palette defined ( 0 "#FF0000", 10000 "#00FF00" )
set cbrange[0:10000]

filename="${tmp}"
plot filename using 1:3:4:xtic(2) with boxes linecolor palette, \
                filename using 1:3:(\$3 == 0 ? "" : \$3) with labels rotate by 270 lc "#000000"
EOF
done
