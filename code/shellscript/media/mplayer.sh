#!/bin/sh
# jsh-ext-depends: killall
# jsh-ext-depends-ignore: expand xscreensaver
# jsh-depends: unj verbosely

# if [ "$USE_SCREEN_LIKE_MADPLAY" ]
# then
	# echo "Called: mplayer $*" >> /tmp/mplayer_script.log
	# madplay "$@"; exit
# fi

# OPTS="-vo gl,xv,x11" ## under gentoo this selects x11 which is slow.  gl sucks for me under compiz
OPTS="-vo x11" ## No acceleration, always works.  Lets me adjust contrast.  Works under compiz.
# OPTS="-vo xv" ## I thought this allowed us to adjust contrast but it doesn't right now.
# OPTS="-vo sdl" ## good if the machine is slow (but not so pretty)
## OK all -vo options turned off.  Recommend setting in /etc/mplayer/mplayer.conf or ~/.mplayer.conf
## Audio driver defaults to /etc/mplayer.conf or ~/.mplayer/config?
# OPTS="$OPTS -ao sdl -zoom -idx"
OPTS="$OPTS -zoom -idx"  # -vf scale
OPTS="$OPTS -stop-xscreensaver"
OPTS="$OPTS -cache 8192"

while true
do
	case "$1" in
		-turbo)
			OPTS="$OPTS -vo sdl"; shift
		;;
		-loud)
			OPTS="$OPTS -af volume=+20dB"; shift
		;;
		-louder)
			OPTS="$OPTS -af volume=+30dB"; shift
		;;
		-quiet)
			OPTS="$OPTS -af volume=-20dB"; shift
		;;
		-putsubsbelow)
			OPTS="$OPTS -vf expand=0:-140:0:+70 -subpos 100"; shift
		;;
		-fast)
			FAST=1 ; shift
		;;
		-faster)
			FAST=2 ; shift
		;;
		-morebass)
			EQ="morebass" ; shift
		;;
		-moremiddle)
			EQ="moremiddle" ; shift
		;;
		-moretreble)
			EQ="moretreble" ; shift
		;;
		*)
			break
		;;
	esac
done

[ "$FAST" ] || FAST=0
## Some highly compressed videos can be too slow to fully decompress!
# FAST=1
## Mplayer recommends:
# [ "$FAST" ] && OPTS="$OPTS -ao sdl -vfm ffmpeg -lavdopts lowres=1:fast:skiploopfilter=all"
## But I found this was enough for me and not so bad quality (autoq/sync may not be needed):
## G's A:
# [ "$FAST" = 1 ] && OPTS="$OPTS -vfm ffmpeg -autoq 5 -autosync 5"
## KMD under Compiz:
# [ "$FAST" ] && OPTS="$OPTS -vfm ffmpeg -autoq 5 -autosync 5 -framedrop -hardframedrop"
## BSG S3:
# [ "$FAST" ] && OPTS="$OPTS -vfm ffmpeg -lavdopts lowres=1:fast -autoq 5 -autosync 5"
## Enterprise:
# [ "$FAST" ] && OPTS="$OPTS -vfm ffmpeg -lavdopts lowres=2:fast -autoq 5 -autosync 5"
## BSG S4.  lowres has no affect, -vo sdl helped SMPlayer under a busy compiz
## but prevents gamma correction (works ok in smplayer anyway):
## -vo x11 appears to work better than -vo xv under compiz.  sometimes with xv
## we get "X11 error: BadAlloc (insufficient resources for operation)"
# [ "$FAST" ] && OPTS="$OPTS -vo x11 -vfm ffmpeg -autoq 5 -autosync 5 -framedrop"
## Others (Sunny highly compress h264):
# [ "$FAST" ] && OPTS="$OPTS -nobps -ni -forceidx -mc 0"

## The last video I tried had A/V sync issues with all of the below configurations, but using more threads seemed to help.  I think -autosync 5 worked better than 30 in that case.
[ "$FAST" -gt 1 ] && OPTS="$OPTS -lavdopts threads=4 -autosync 5"
#[ "$FAST" -gt 1 ] && OPTS="$OPTS -lavdopts threads=4:lowres=0:fast:skiploopfilter=all -autosync 5 -sws 4"
## A/V sync is only lost when I use x11 driver in fullscreen with -zoom.
## So one option for large videos is to remove -zoom and avoid fullscreen.
## The A/V can always be resynced by doing one of the following:
## - Switch out of fullscreen and back in (catches up)
## - Increase and decrease playbackspeed with ] then immediately [ (catches up)
## - Rewind and forwardwind (immediate resync)
## TODO: Does -sws 4 help?

## autosync 1 has a special meaning, so it is worth trying before trying a higher value.
[ "$FAST" -gt 2 ] && OPTS="$OPTS -vfm ffmpeg -lavdopts lowres=0:fast:skiploopfilter=all -autosync 1"
## Note that -framedrop can be undesirable if the video is a highly-compressed
## h264 - it will cause us to frequently lose large chunks!

## A heavy flv from YouTube (crashes on HTLGI video!):
[ "$FAST" -gt 3 ] && OPTS="$OPTS -vfm ffmpeg -lavdopts lowres=0:fast:skiploopfilter=all -autoq 5 -autosync 5 -framedrop -nocorrect-pts"

## On pod -ao sdl was failing to keep up (clipping and reporting underruns, P&R) whilst -ao alsa was fine.  Leaving -ao sdl until desperate.
## This may be wrong for hwi - hwi's default alsa is significantly slower than sdl because it duplexes.
[ "$FAST" -gt 4 ] && OPTS="$OPTS -ao sdl"

## -vo sdl is the sort of thing you can do yourself, if you remember to.
#[ "$FAST" -gt 5 ] && OPTS="$OPTS -vo sdl" &&
#                     REMEMBER_WINDOW_POSITIONS=true   # If sdl drops X resolution, window positions may be lost!

## lowres=1 crashes on many videos, on just a few it makes decoding faster but with lower image quality
[ "$FAST" -gt 8 ] && OPTS="$OPTS -vfm ffmpeg -lavdopts lowres=1:fast:skiploopfilter=all -autoq 5 -autosync 5 -framedrop -nocorrect-pts -nobps -ni -mc 0 -vo sdl"



## AFAIK VNC only works with the x11 vo:
if [ "$VNCDESKTOP" = "X" ]
then OPTS="$OPTS -vo x11"
fi
## xv is more efficient though

## When changing speed (with [ and ] or -speed), keep pitch the same
## TODO: This breaks the volume filter when enabled.  Perhaps we need to specify both in one -af option...?
#OPTS="$OPTS -af scaletempo"

## Graphic equalizer
[ "$EQ" ] || EQ="none"

# Boost the bass if you have cheap headphones or small speakers.
#[ "$EQ" = morebass ]   && OPTS="$OPTS -af equalizer=4:3:2:1:1:0:0:0:0:0"

# Actually boost the bass by reducing everything else
[ "$EQ" = hardbass ]   && OPTS="$OPTS -af equalizer=2:1:0:-1:-1:-2:-2:-2:-2:-2"

# Boost the middle and the bass a little, for a warmer feel on a nice speaker set.
#[ "$EQ" = morebass ]   && OPTS="$OPTS -af equalizer=2:2:1:0:-1:-2:-2:-2:-2:-2"

# Boost the bass a lot
[ "$EQ" = morebass ]   && OPTS="$OPTS -af equalizer=3:3:2:1:0:-1:-2:-2:-2:-2"

# Boost the middle and the bass a little, for a warmer feel on a nice speaker set.
[ "$EQ" = softbass ]   && OPTS="$OPTS -af equalizer=2:2:1:1:0:0:-1:-1:-2:-2"

# Boost the middle and the bass a little, for a warmer feel on a nice speaker set.
[ "$EQ" = moremiddle ] && OPTS="$OPTS -af equalizer=2:3:3:2:1:0:0:0:0:0"

# Reduce the bass if you have too much bass, or want to boost the highs
[ "$EQ" = moretreble ] && OPTS="$OPTS -af equalizer=-4:-4:-3:-3:-2:-2:-1:-1:0:0" ## Quieter bass

# [ "$EQ" = wireless ]   && OPTS="$OPTS -af equalizer=0:0:1:1:2:2:3:3:4:4" ## Louder middle and treble (can cause crackle)

if [ "$SHORTHOST" = "hwi" ]
then
	#                     gam:con:bri:sat:rg :gg :bg :weight
	# OPTS="$OPTS -vf eq2=1.0:1.0:0.0:1.0:0.6:1.0:1.0"  ## Fix red gamma on hwi
	# OPTS="$OPTS -vf eq2=1.0:1.0:0.0:1.0:0.7:1.0:1.0"  ## Fix red gamma on hwi
	# OPTS="$OPTS -vf eq2=1.0:1.2:0.0:1.0:0.8:1.1:1.1"  ## Fix red gamma on hwi and increase contrast
	# OPTS="$OPTS -vf eq2=1.2:1.0:0.0:1.0:1.0:1.1:1.1"  ## Fix red gamma on hwi and increase gamma
	OPTS="$OPTS -vf eq2=1.3:1.0:0.05:1.0:0.7:1.0:1.1"  ## Fix red gamma on hwi, extra gamma and a little brightness
	# OPTS="$OPTS -vo x11" ## keeps my x gamma fixes, but doesn't scale (don't use this and eq2!)
	# OPTS="$OPTS -vo gl"  ## keeps x fixes, but a little blue just like eq2
fi

## See also: new versions of mplayer have a -stop-xscreensaver option
## consider: could killall -STOP it, then unhalt it at end.
killall xscreensaver && XSCREENSAVER_WAS_RUNNING=true
## Despite Debian accepting the -stop-xscreensaver option now, xscreensaver still appears!

[ "$REMEMBER_WINDOW_POSITIONS" ] && wmctrl_store_positions

[ "$MPLAYER" ] || MPLAYER=mplayer
verbosely unj $MPLAYER $OPTS "$@"

[ "$REMEMBER_WINDOW_POSITIONS" ] && wmctrl_restore_positions

[ "$XSCREENSAVER_WAS_RUNNING" ] && xscreensaver -no-splash &

#
#            ************************************************
#            **** Your system is too SLOW to play this!  ****
#            ************************************************
#
# Possible reasons, problems, workarounds:
# - Most common: broken/buggy _audio_ driver
#   - Try -ao sdl or use the OSS emulation of ALSA.
#   - Experiment with different values for -autosync, 30 is a good start.
# - Slow video output
#   - Try a different -vo driver (-vo help for a list) or try -framedrop!
# - Slow CPU
#   - Don't try to play a big DVD/DivX on a slow CPU! Try some of the lavdopts,
#     e.g. -vfm ffmpeg -lavdopts lowres=1:fast:skiploopfilter=all.
# - Broken file
#   - Try various combinations of -nobps -ni -forceidx -mc 0.
# - Slow media (NFS/SMB mounts, DVD, VCD etc)
#   - Try -cache 8192.
# - Are you using -cache to play a non-interleaved AVI file?
#   - Try -nocache.
# Read DOCS/HTML/en/video.html for tuning/speedup tips.
# If none of this helps you, read DOCS/HTML/en/bugreports.html.

