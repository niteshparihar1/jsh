#!/bin/sh
# jsh-depends: playmp3andwait takecols chooserandomline filename
# jsh-depends-ignore: music del

## Create playlist.last as we go, so we can look back in history.
## Also create playlist.potential at the start (the filtered/grepped memo) so that audacious can do something similar if we need to drop randommp3.

## TODO: Have mp3gain not change the file, but create a tiny file to cache the results of the mp3gain scan.  Use mp3gain to apply the (cached) result to a temporary copy of the mp3 before playing.

DEBUG=true

MP3INFOEXE=`which mp3info 2>/dev/null`

domp3info () {
	if [ -x "$MP3INFOEXE" ]
	then "$MP3INFOEXE" "$@"
	else echo "[mp3info not installed]"
	fi
}

SEARCH="$*"


# This script finds all your music in this file
AUDIO_FILES_LIST="$HOME/Music/jsh_audio_files.m3u"
#AUDIO_FILES_LIST="$HOME/Music/all_tracks.m3u"

CURRENT_PLAYLIST="$HOME/Music/current_playlist.m3u"
mkdir -p "$HOME/Music"

# Old location
[ ! -f "$AUDIO_FILES_LIST" ] && AUDIO_FILES_LIST="$JPATH/music/search_results.m3u"

if [ ! -f "$AUDIO_FILES_LIST" ]
then updatemusiclist | dog "$AUDIO_FILES_LIST"
fi

# Can be overriden by setting JSH_ALL_AUDIO_FILES
[ -n "$JSH_ALL_AUDIO_FILES" ] && AUDIO_FILES_LIST="$JSH_ALL_AUDIO_FILES"

# Generate the file if it does not exist

if [ ! -f "$AUDIO_FILES_LIST" ]
then memo -t "2 days" updatemusiclist > "$AUDIO_FILES_LIST"
fi

cat "$AUDIO_FILES_LIST" |

grep -i "$SEARCH" |
# grep -v -i "\<book\>" |
dog "$CURRENT_PLAYLIST"

if [ ! "x$SEARCH" = "x" ]
then
	jshinfo "$(cat "$CURRENT_PLAYLIST" | wc -l) tracks found matching \"$SEARCH\"."
	echo
fi

## GET_FILE_LIST="memo -t '2 days' updatemusiclist"
# memo -t "2 hours" updatemusiclist
# memo -t "2 days" updatemusiclist

if which mp3gain > /dev/null 2>&1 && [ ! "$DONT_USE_MP3GAIN" ]
then
	USE_MP3GAIN=true
	NORMALISEDTRACK="/tmp/randommp3-gainchange.mp3"
	NORMALISEDTRACK2="/tmp/randommp3-gainchange-2.mp3"
fi

FIRSTLOOP=true

while true
do

	# TRACK=`cat $JPATH/music/list.m3u | grep -i "$SEARCH" | chooserandomline`
	# TRACK=`memo -t '2 days' updatemusiclist | grep -i "$SEARCH" | grep -v -i "\<book\>" | chooserandomline`
	TRACK=`cat "$CURRENT_PLAYLIST" | chooserandomline`

	[ ! -f "$TRACK" ] && continue

	# Preprocess the track, but not on the first loop

	## Normalise volume (gain)
	TRACKTOPLAY="$TRACK"
	## TODO: what if it fails, eg. ogg, will not know when playing, will probably play previous track!
	## Now we also skip if ut is running (in that case on gentoo the niceness causes mp3gain to take ages but still cause tiny bits of lag to ut (which was nice 0).
	# if [ "$USE_MP3GAIN" ] && [ ! "$FIRSTLOOP" ] && endswith "$TRACK" "\.mp3" ## because mp3gain does nasty things with oggs (like filling up the computer's memory?!)
	echo "`cursenorm;cursebold`Next track: `cursemagenta`$TRACK`cursenorm`" >&2
	if [ "$USE_MP3GAIN" ] && [ -n "$DEBUG" ] || [ ! "$FIRSTLOOP" ] && echo "$TRACK" | grep -i "\.mp3$" >/dev/null && ! findjob "ut-bin\>" >/dev/null ## because mp3gain does nasty things with oggs (like filling up the computer's memory?!)
	then
		# echo "`curseblue`Normalising next track: `cursemagenta`$TRACK`cursenorm`" >&2

		## TODO: This block can be removed once i've un-mp3gained my collection!
		curseblue
		undomp3gain "$TRACK" # >/dev/null 2>&1
		cursenorm

		TMPFILE="$NORMALISEDTRACK"
		nice -n 18 mp3gainhelper "$TRACK" "$TMPFILE" &&
		TRACKTOPLAY="$TMPFILE"

		## Swap round tmpfile names, so mp3gain doesn't interfere with player.
		TMP="$NORMALISEDTRACK"
		NORMALISEDTRACK="$NORMALISEDTRACK2"
		NORMALISEDTRACK2="$TMP"

		## Before we play it, the whatsplaying script wants to know the original track file:
		echo "$TRACK" > "$NORMALISEDTRACK".whatsplaying

		echo "`cursegreen`Done normalising track: $TRACK`cursenorm`" >&2
	fi

	# [ "$FIRSTLOOP" ] || echo "`curseblue`Waiting for current track to finish playing.`cursenorm`"
	wait

	echo
	echo "--------------------------------------"
	echo

	xttitle "randommp3: `domp3info -p "%a - %t" "$TRACK" 2>/dev/null` [`filename "$TRACK"`]"

	## Inform the log
	if [ -d "$JPATH/logs" ]
	then echo "$TRACK" >> $JPATH/logs/xmms.log
	fi


	SHOW_OLD_OUTPUT_FORMAT=

	if [ -n "$SHOW_OLD_OUTPUT_FORMAT" ]
	then

		## Echo output to user
		# SIZE=`du -sh "$TRACK" | takecols 1`
		[ -x "$MP3INFOEXE" ] && SIZE=`mp3duration "$TRACK" | takecols 1`
		# echo "$SIZE: "`curseyellow``cursebold`"$TRACK"`cursenorm`
		echo "\""`curseyellow``cursebold`"$TRACK"`cursenorm`"\" ($SIZE)"

		MP3INFO=`domp3info "$TRACK" 2>/dev/null`

		echo "$MP3INFO" |
		grep -v "^File: " | grep -v "^$" |
		sed "s+[[:alpha:]]*:+`cursemagenta`\0`cursenorm`+g" |
		# sed "s+\(File:[^ ]* \)\(.*\)+`curseblue`\1 `curseblue`\2+"
		cat

		# (
		# echo "`domp3info -p "%a - %t" "$TRACK" 2>/dev/null` :: [`filename "$TRACK"`]"
		# # echo "randommp3: `domp3info -p "%a - %t" "$TRACK" 2>/dev/null` [`filename "$TRACK"`]"
			# # echo "$MP3INFO"
		# ) |
		# # osd_cat -c green -f '-*-lucida-*-r-*-*-*-200-*-*-*-*-*-*'
		# osd_cat -c green -f '-*-lucida-*-r-*-*-*-200-*-*-*-*-*-*'
		## This is now a duplicate of whatsplaying:
		FILE="$TRACK"
		NAME=` domp3info -p "%a - %t" "$FILE" `
		TIME=` domp3info -p "%mm%ss" "$FILE" `
		(
			echo "$NAME"
			echo " \\_ $TIME :: [$FILE]" 
		) |
		# osd_cat -c green -f '-*-freesans-*-r-*-*-*-240-*-*-*-*-*-*' &
		osd_cat -c green -f '-*-lucidabright-medium-r-*-*-26-*-*-*-*-*-*-*' & ## works inside my chroot

	else

		showsonginfo "$TRACK" >/dev/null 2>&1

	fi

	echo
	echo "`curseyellow`If you don't like this song, you can delete the file (and its cachefiles) with:`cursenorm`"
	echo
	echo "    `cursered`del \"$TRACK\"(|.mp3gain)`cursenorm`" # also cleans up any associated mp3gain file :)
	echo


	# [ "$USE_MP3GAIN" ] && [ ! "$FIRSTLOOP" ] && TRACK="$NORMALISEDTRACK"

	# if [ -x /usr/bin/time ]
	# then /usr/bin/time -f "%e seconds ( Time: %E CPU: %P Mem: %Mk )" playmp3andwait "$TRACK" &
	# else playmp3andwait "$TRACK" &
	# fi
	# echo "randommp3: `domp3info -p "%a - %t" "$TRACK" 2>/dev/null` [`filename "$TRACK"`]" | osd_cat -f '-*-lucida-*-r-*-*-*-440-*-*-*-*-*-*'
	if [ "$USE_MP3GAIN" ]
	then
		playmp3andwait "$TRACKTOPLAY" #>/dev/null 2>&1 &
		## Gives the player a bit of time to establish and cache the file, so mp3gain doesn't steal vital CPU!
		#sleep 10
	else
		playmp3andwait "$TRACKTOPLAY" #>/dev/null #2>&1
	fi
	echo
	# CONSIDER: if [ ! "$TRACKTOPLAY" = "$TRACK" ]; then we can assume the track's mp3 gain has been corrected, and in this case we can/should play the track a bit louder than non-corrected tracks!

	FIRSTLOOP=

done
