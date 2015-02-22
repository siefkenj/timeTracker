#!/bin/bash

# Watches .coffee and .jade and .styl files and comiles them
# wheneeer they change


WATCHABLE=(coffee jade styl)

compile() {
	FILENAME="$1"
	EXTENSION=${FILENAME##*.}
	if [[ "$EXTENSION" == "coffee" ]]
	then
		coffee -bc "$FILENAME"
	fi
	if [[ "$EXTENSION" == "styl" ]]
	then
		stylus -w "$FILENAME" -u nib
	fi
	if [[ "$EXTENSION" == "jade" ]]
	then
		jade --pretty "$FILENAME"
	fi
}

is_watchable() {
	EXTENSION=${i##*.}
	if [[ `echo "${WATCHABLE[*]}"|grep $EXTENSION` != "" ]]
	then
		echo "matchable!!"
		return 0
	fi
	return 1
}

declare -A WATCHED_FILES

for i in `find .`
do
	if is_watchable $i
	then
		echo "Watching: $i"
		WATCHED_FILES["$i"]=`md5sum "$i"|sed -e 's/\s.*//'`
	fi
done

## reminder
#echo "${WATCHED_FILES[@]}"  all the values
#echo "${!WATCHED_FILES[@]}"  all the keys

while true
do
	for i in "${!WATCHED_FILES[@]}"
	do
		NEW_SUM=`md5sum "$i"|sed -e 's/\s.*//'`
		OLD_SUM="${WATCHED_FILES[$i]}"
		if [ "$NEW_SUM" != "$OLD_SUM" ]
		then
			echo "Changed file '$i'; Compiling:"
			WATCHED_FILES["$i"]=$NEW_SUM
			compile $i
		fi
	done
	sleep 1
done
