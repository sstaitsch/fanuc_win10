#!/bin/bash

##########################################################
#	This program extracts all programs individually from
#	the *.ALL into individual files.
#
#	Tested to FANUC version
#		0i, 16i, 18i, 31i
#
#	Runs on Linux, Android and Windows
#	(with additional installation of a Linux shell from Microsoft-Store)
#
#	Coded by Sebastian Staitsch
#	s.staitsch@gmail.com
#	Version 1.4
#	last modified: 2020/07/03 01:35:46
#	https://github.com/sstaitsch/fanuc
#	https://pastebin.com/4wFFYnw3
#
#	=== VIDEO ===
#	https://youtu.be/zgsBnk39xLI
#
#	NOTE: 	-Files must be in the same folder as the script file
#			-Files must have the suffix * .ALL
#
#	USE: sh fanuc.sh
##########################################################

#GET VERSION
	get_ver(){
		if [ "$(grep -E -o '<|>' $file)" ] ; then v=31
		elif [ "$(grep -E -o '^O{1}[0-9]{4}' $file)" ] ; then v=18
		else exit
		fi
	}
#READ PROGRAMM-NAME
	read_oname(){
		if [ "$v" = "18" ]; then
			ONAME=$(grep -E -om1 'O{1}[0-9]{4}' $file)
		elif [ "$v" = "31" ]; then
			ONAME=$(grep -E -om1 '^<{1}\S*>{1}' $file | tr -d '<>')
		else exit
		fi
	}
#DELETE CR/LF AND PRERCENT-SYMBOL
	del_crlf(){
		cat $file | tr -d '\r%' > .tmp ; rm $file ; mv .tmp $file
	}
#READ FIRST LINE
	read_line(){
		line_1=$(cat $file | head -1)
	}
#DELETE FIRST LINE
	del_line(){
		tail -n+2 $file > .tmp ; rm $file ; mv .tmp $file
	}
#LOOP VERSION 18
	loop_18(){
		until [ "$(cat $file | wc -l)" = 0 ]; do
			read_line
			if [ $(echo $line_1 | grep -E -o 'O{1}[0-9]{4}') ]; then
				read_oname
				echo $line_1
				echo $v$file/$line_1 >> .list
			fi
			echo $line_1 >> $v$file/$ONAME
			del_line
		done
	}
#LOOP VERSION 31
	loop_31(){
		read_oname
		until [ "$(cat $file | wc -l)" = 0 ]; do
			read_line
			if [ $(echo $line_1 | grep -E -o '^<') ]; then
				read_oname
				echo $line_1
				echo $v$file/$line_1 >> .list
			fi
			echo $line_1 >> $v$file/$ONAME
			del_line
		done
	}

#MAIN PROGRAMM
	if [ ! $( ls *.ALL 2>/dev/null ) ] ; then
		echo "No *.ALL Files found" ; exit 2
	fi
	numberfiles=$(ls *ALL | wc -l)
	clear
	echo Find $numberfiles Files
	echo Process is started...
	clear

	for file in *ALL ; do
		echo ======================================
		echo NOW SPLIT FILE $file
		echo ======================================
		cp $file $file.bak
		del_crlf
		get_ver
		mkdir $v$file
			if [ "$v" = "18" ]; then loop_18
				elif [ "$v" = "31" ]; then loop_31
				else exit
			fi
		rm $file
		mv $file.bak $file
		echo ======================================
		echo Extracted $(ls $v$file | wc -l ) Programs from $file
	done

#ADD %-SYMBOL TO EVERY FILE
	for file in */*; do
		echo "%" > $file.tmp
		cat $file >> $file.tmp
		echo "%" >> $file.tmp
		rm $file
		mv $file.tmp $file
	done

#CREATE A SORTED PROGRAMMLIST
	cat .list | sort > prglist.txt
	rm .list

#RENAME FOLDER
	for folder in */; do mv $folder v_$folder; done

#CREATE A ZIP-FILE
	d=`date +%d-%m`
	zip -r $d * 1>/dev/null

#CLOSING REPORT
	echo "===== TASK DONE ====="
	echo $(wc -l prglist.txt | sed 's/prglist.txt//') programs were exported from $numberfiles files


