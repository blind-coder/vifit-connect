#!/bin/bash
days="43000000000000000000000000000043 43010000000000000000000000000044 43020000000000000000000000000045 43030000000000000000000000000046 43040000000000000000000000000047 43050000000000000000000000000048 43060000000000000000000000000049 4307000000000000000000000000004a 4308000000000000000000000000004b 4309000000000000000000000000004c 430a000000000000000000000000004d 430b000000000000000000000000004e 430c000000000000000000000000004f 430d0000000000000000000000000050 430e0000000000000000000000000051"

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
for day in ${days}; do
	./getData.expect ${day} > "${tmp}"
	if [ $( grep -c '0x0038 value: 43' "${tmp}" ) -lt 5 ]; then
		# No more records
		exit
	fi
	while read yy mm dd idx type lsb msb; do
		[ "${idx}" == "00" ] && echo -n > "20${yy}-${mm}-${dd}.log"
		if [ "${type,,}" == "ff" ]; then
			continue
		fi
		read t < <( echo "${idx}" | hex2dec )
		read steps < <( echo "${msb}${lsb}" | hex2dec )
		printf "%d %02d:%02d %s\n" ${t} $((${t}/4)) $((${t}%4*15)) "${steps}" >> "20${yy}-${mm}-${dd}.log"
	done < <( grep '0x0038 value: 43' "${tmp}" | cut -f09-11,12-13,16-17 -d' ' )
	#^[[0;94m[20:cd:39:ad:e5:bc]^[[0m[LE]> ^M^[[KNotification handle = 0x0038 value: 43 f0 15 05 19 32 00 34 05 82 01 1b 00 00 00 6f
  #    01                                          02        03   04    05    06   07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22
done
