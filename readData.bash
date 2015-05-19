#!/bin/bash

hex2dec () 
{ 
	local l x;
	while read l; do
		for x in ${l};
		do
			echo -n "$((16#${x})) ";
		done;
		echo;
	done
}

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT
./getData.expect 43000000000000000000000000000043 >> "${tmp}"
while read idx type lsb msb; do
	if [ "${type,,}" == "ff" ]; then
		continue
	fi
	read t < <( echo "${idx}" | hex2dec )
	read steps < <( echo "${msb}${lsb}" | hex2dec )
	printf "%02d:%02d %s\n" $((${t}/4)) $((${t}%4*15)) "${steps}"
done < <( grep '0x0038 value: 43' "${tmp}" | cut -f12-13,16-17 -d' ' )
cat ${tmp} > foo
