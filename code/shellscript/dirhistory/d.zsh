# d: change directory and record for b and f shell tools

# Shouldn't we remember moved-into, not moved-out-of?

# Sometimes NEWDIR="$@" breaks under ssh!

NEWDIR="$@"

# Record where we are for b and f sh tools
echo "$PWD" >> $HOME/.dirhistory

if [ "$NEWDIR" = "" ]; then
  # I prefer the directory above my home!
  "cd" $HOME/..
  # "cd"
elif test -d "$NEWDIR"; then
  'cd' "$NEWDIR"
else
	DIRNAME=`dirname "$NEWDIR"`
	FILENAME=`filename "$NEWDIR"`
	# If incomplete dir given, check if there is a
	# unique directory they probably meant.
	# Useful substitue when tab-completion unavailable,
	# or with tab-completion which does not contextually exclude files.
	# NEWLIST=`'ls' -d "$NEWDIR"* |
	NEWLIST=`find "$DIRNAME" -name "$FILENAME"'*' -maxdepth 1 |
		while read X; do
			if test -d "$X"; then
				echo "$X"
			fi
		 done`
	if test "$NEWLIST" = ""; then
		echo "< $DIRNAME"
		'cd' "$DIRNAME"
	elif test `echo "$NEWLIST" | countlines` = "1"; then
		echo "> $NEWLIST"
		'cd' "$NEWLIST"
		DIRNAME=`dirname "$NEWDIR"`
	else
		echo "$NEWLIST ?" | tr "\n" " "
		echo
		# echo -n "$NEWLIST" | tr "\n" " "
		# echo " ?"
	fi
fi

# pwd >> $HOME/.dirhistory
