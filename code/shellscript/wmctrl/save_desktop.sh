## TODO: If there is already an existing (unreceovered) $TARGET_FILE, then don't overwrite it!  But do what ... ?
## TODO: More state needs to be saved for certain types of windows.
## TODO: Any chance we can restore fluxbox's tabbing?  E.g. by preparing it's auto-tab settings?  Hmm we must detect tabbed windows to begin with, maybe by location.
## TODO: Don't pop up dialog xterms if Xdialog is available!
## TODO: Term-apps should restore cwd of shell, "extra" environment vars, scrollback (pipe it to the new pts? But how do we get it?!), command-history (possible with patch to .bash_history).
## TODO: We could use pstree or ps axjf, to see if the user ran something from the shell inside each xterm (if it's not an xterm -e), and if so restore that call!  (e.g. could be a vim or ssh.).  Also we want to get the cwd of the shell.

if [ "$1" = "-test" ]
then DUMMY=1 ; shift
fi

SAVE_ALL=
if [ "$1" = -all ]
then
	shift
	SAVE_ALL=1
fi

if [ "$1" = -ask ]
then
	shift
	DESKTOP="$1" ; shift
	TARGET_FILE="$1" ; shift
	PIDS="$*"
	jshinfo "Saved desktop $DESKTOP to $TARGET_FILE:"
	echo
	cat "$TARGET_FILE"
	echo
	jshinfo "I will kill PIDs: $PIDS"
	echo
	jshquestion "Shall I kill the processes now? [Y/n] "
	read ANSWER
	if [ "$ANSWER" = y ] || [ "$ANSWER" = Y ] || [ "$ANSWER" = "" ]
	then verbosely kill $PIDS
	fi
	exit
fi

export COLUMNS=65535

if [ "$SAVE_ALL" ]
then DESKTOP_MARKER_RE="[\*\-]"
else DESKTOP_MARKER_RE="\*"
fi

DESKTOPS=` wmctrl -d | grep "[^ ]* *$DESKTOP_MARKER_RE" | takecols 1 `

TARGET_DIR="$HOME/Desktop/OldSessions"
mkdir -p "$TARGET_DIR"
PIDS_FILE=/tmp/save_desktop_pids.$$.tmp

for DESKTOP in $DESKTOPS
do

	TARGET_FILE="$TARGET_DIR/$DESKTOP.session_sh"

	(
		echo "## State of desktop $DESKTOP at `date`:"
		echo
	) > "$TARGET_FILE"
	printf "" >> "$PIDS_FILE"

	if [ "$SAVE_ALL" ]
	then
		echo "wmctrl -s $DESKTOP"
		echo
	fi

	wmctrl -l -p -G -x | grep "^[^ ]*  *$DESKTOP " |

	# tee /tmp/save_desktop.debug |

	## This loop should output the commands needed to restore each window.
	## Duplicates will be trimmed.
	while read ID DESKTOP PID X Y W H WM_CLASS TITLE
	do

		PROCESS_COMMAND=` ps aux | grep "^[^ ]*  *$PID " | dropcols 1 2 3 4 5 6 7 8 9 10 `

		## Problems with PROCESS_COMMAND:
		## BUG: Grouping of any arguments containing spaces has been lost!
		## We guess where they are:
		## Fix for xterm -title args which are often followed by -e in my scripts.
		PROCESS_COMMAND=` echo "$PROCESS_COMMAND" | sed "s/ -title \(.*\) -e / -title '\1' -e /" `
		# PROCESS_COMMAND=` echo "$PROCESS_COMMAND" | sed "s/ -title \(.*\) -e \(.*\)/ -title '\1' -e '\2'/" `
		## Quote-escape arguments containing '*' or '#'.  TODO: Other unwanted chars we must escape.
		PROCESS_COMMAND=` echo "$PROCESS_COMMAND" | sed "s/ \([^ ]*[*#][^ ]*\) / '\1' /g" `

		## TODO BUG For xterms, this is the cwd of the xterm when it started.
		##          But really we want the cwd of the shell running inside the xterm!
		PROCESS_CWD=` lsof -p "$PID" | grep "  cwd  " | head -n 1 | dropcols 1 2 3 4 5 6 7 8 `

		## Fluxbox size-creep bug
		H=$((H-12))
		X=$((X-1))
		Y=$((Y-55))

		if [ "$WM_CLASS" = xterm.XTerm ]
		then
			# jshinfo "Converting $W x $H"
			W=$((W/7))
			H=$((H/12))
			# jshinfo "        to $W x $H"
		fi
		GEO="$W"x"$H+$X+$Y"

		## Drop any geometry args the window was started with before.  (Might be interesting to compare tho!)
		PROCESS_COMMAND=` echo "$PROCESS_COMMAND" | sed 's/ -geometry [^ ]* / /g' `
		## Insert new geometry after first space.
		PROCESS_COMMAND=` echo "$PROCESS_COMMAND" | sed "s/ / -geometry $GEO /" `

		## TODO:
		## Browsers - what URL(s) are they viewing now?
		## File explorers, other document viewers (title=file?!).
		## xterms  may have a command running in them, e.g. the user started a vim in that terminal, or an ssh session, or had run mplayer on something.
		## ...
		## On restoring, we should go slowly, and check/detect to avoid duplication.  This may occur if we respawn an xterm that spawns a window app.

		if [ "$DUMMY" ]
		then

			jshinfo "PID: $PID"
			jshinfo "Command: $PROCESS_COMMAND"
			jshinfo "Geometry: $GEO"
			jshinfo "Location: $PROCESS_CWD"
			jshinfo

		fi

		(
			# echo "cd '$PROCESS_CWD' &&"
			# echo "$PROCESS_COMMAND &"
			echo "cd '$PROCESS_CWD' && $PROCESS_COMMAND &"
			echo
		)

		echo "$PID" >> "$PIDS_FILE"

	done |
	removeduplicatelines >> "$TARGET_FILE"

	if [ "$SAVE_ALL" ]
	then echo "sleep 10   ## Give time for windows to load, before we switch desktop." >> "$TARGET_FILE"
	fi

	jshinfo "Saved to $TARGET_FILE"

done

PIDS=` cat "$PIDS_FILE" | tr '\n' ' ' `
rm -f "$PIDS_FILE"
# jshinfo "PIDS=$PIDS"

bigwin -fg save_desktop -ask "$DESKTOP" "$TARGET_FILE" "$PIDS"
