#!/bin/sh

## TODO: locking of jshstub's if another jshstub is already trying to retrieve the link

## TODO: if we identify that this call was a source, shouldn't we source the target?

## Goddammit I have that classic problem when bash sources us!

## For bash: hmmm still working on it
# echo "jshstub: $SCRIPTNAME ( $_ | $0 | $# | $* | $FUNCNAME )" >&2
# echo "\$\_ = >$_<" >&2
# echo "\$\0 = >$0<" >&2
# echo "\$\# = >$#<" >&2
# echo "\$\* = >$*<" >&2
# echo "\$\FUNCNAME = >$FUNCNAME<" >&2
# set > /tmp/set.out >&2
# env > /tmp/env.out >&2
# history > /tmp/history.out >&2

SCRIPTFILE="$0"
## note not yet absolute path
SCRIPTNAME=`basename "$SCRIPTFILE"`

# test $SCRIPTNAME = bash &&
# echo "AAA = $TOSOURCE" | tee -a /tmp/jshstub.log >&2 &&
# echo "SCRIPTNAME=$SCRIPTNAME TOSOURCE=$TOSOURCE" >&2
# if test "$SCRIPTNAME" = bash && test "$TOSOURCE"
# then
	# test ! "${TOSOURCE##/*}" && SCRIPTFILE="$TOSOURCE" || SCRIPTFILE="$JPATH/tools/$TOSOURCE"
	# SCRIPTNAME=`basename "$SCRIPTFILE"`
# fi

## TODO: need a better check than this! (would need absolute path at least)
# TOOLDIR="$JPATH/tools"
# if test ! "`dirname "$SCRIPTFILE"`" = "$TOOLDIR"
# then
	# echo "jshstub: Aborting because $SCRIPTFILE is not in \$JPATH/tools" >&2
	# exit 1
# fi

OKTOGO=true
GOTBYANOTHERSTUB=

if test "$SCRIPTNAME" = jshstub
then
	echo "[ jshstub: Refusing to retrieve another copy of jshstub! ]" >&2
	OKTOGO=
fi

if test ! -L "$SCRIPTFILE"
then
	## If this script was sourced by name then $0 has filename but no path.  Try this path:
	if test -L "$JPATH/tools/$SCRIPTFILE"
	then
		SCRIPTFILE="$JPATH/tools/$SCRIPTFILE"
		## But of course this doesn't always work 'cos startj is often sourced with full path!
		SCRIPT_WAS_SOURCED="(sourced) "
		# echo "[ jshstub: (Looks like this script was sourced) ]" >&2
	else
		## It seems we have problems: when the final call is made, sh caches this script and re-runs it.
		## We end up here, but the caching continues if we try again.
		## This caching problem still occurs occasionally with zsh
		# echo "[ jshstub: Strangely $SCRIPTFILE is not a symlink, trying to run it again... ]" >&2
		# "$SCRIPTFILE" "$@"
		echo "[ jshstub: $SCRIPTFILE is not a symlink! ]" >&2
		OKTOGO=true
		GOTBYANOTHERSTUB=true
	fi
fi

if test $OKTOGO
then

	## Block if another jshstub is getting the script (can happen eg. | highlight ... | highlight ...)
	## TOOD: race condition
	LOCKFILE="$JPATH/tmp/$SCRIPTNAME.jshstub_lock"
	if test -f "$LOCKFILE"
	then
		echo "[ jshstub: Waiting for lock release on $LOCKFILE ]" >&2
		while true
		do
			## Check if lockfile has been cleared yet
			if test ! -f "$LOCKFILE"
			then GOTBYANOTHERSTUB=true; break
			fi
			sleep 1
			## Timeout if lockfile is not cleared after 1 minute
			touch -d "1 minute ago" "$LOCKFILE.compare"
			if test "$LOCKFILE.compare" -nt "$LOCKFILE"
			then
				echo "[ jshstub: Timeout on $LOCKFILE.  Ploughing on... ]" >&2
				ls -l "$LOCKFILE" "$LOCKFILE.compare" >&2
				break
			fi
		done
	fi

	if test ! $GOTBYANOTHERSTUB
	then

		touch "$LOCKFILE"

		rm -f "$SCRIPTFILE"

		echo "[ jshstub: Retrieving $SCRIPT_WAS_SOURCED\"$SCRIPTNAME\" args=$* ]" >&2
		wget -q "http://hwi.ath.cx/jshstubtools/$SCRIPTNAME" -O "$SCRIPTFILE"

		if test ! "$?" = 0
		then
			echo "[ jshstub: Error: failed to retrieve http://hwi.ath.cx/jshstubtools/$SCRIPTNAME ]" >&2
			echo "[ jshstub: Replacing removed symlink ]" >&2
			ln -s "$JPATH/tools/jshstub" "$SCRIPTFILE"
			OKTOGO=
		fi

		chmod a+x "$SCRIPTFILE"

		rm -f "$LOCKFILE"

	fi

	if test $OKTOGO
	then

		echo "[ jshstub: Got script \"$SCRIPTNAME\" ok, running: $SCRIPTFILE $* ]" >&2
		echo >&2

		# if test "$SCRIPT_WAS_SOURCED"
		# then
			# test "$TOSOURCE" &&
			export TOSOURCE="$SCRIPTFILE"
			# echo "ZZZ = $TOSOURCE" | tee -a /tmp/jshstub.log >&2
			# . $JPATH/tools/joeybashsource "$SCRIPTFILE" "$@"
			# echo "ZZZfinished = $SCRIPTFILE $TOSOURCE" | tee -a /tmp/jshstub.log >&2
			# source "$SCRIPTFILE" "$@"
			. "$SCRIPTFILE" "$@"
		# else
			# "$SCRIPTFILE" "$@"
		# fi

	else

		test $OKTOGO ## false

	fi

else

	test $OKTOGO ## false

fi
