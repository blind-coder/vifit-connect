#!/usr/bin/gnuplot

set terminal png size 1280, 768 font "Times,12"
set boxwidth 0.5
set style fill solid
set key off

set xtics rotate by 270
set xlabel "Time"
set ylabel "Steps"

set palette defined ( 0 "#FF0000", 10000 "#00FF00" )
set cbrange[0:10000]

plot filename using 1:3:4:xtic(2) with boxes linecolor palette, \
		 filename using 1:3:($3 == 0 ? "" : $3) with labels rotate by 270 lc "#000000"
