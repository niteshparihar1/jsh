#!/bin/bash
# jsh-ext-depends: find
# jsh-depends-ignore: randomorder there flatdf
# jsh-depends: takecols drop error issymlink

## TODO: Does not cleanup sockets.

## DONE: Now does clean up empty directories, as well as files and symlinks in /RECLAIM.

## TODO: i factored out reclaimfrom but didn't really modify it at all
##       we never reclaim from $HOME/j/trash but we should!  (If we are on a nicely working system, or we are root, we can easily do this by doing del on those trash folders, before we start the reclaim ^^ )

## TODO BUG:
# Space increased to: 50692
# But I failed to reclaim: ./tmp/jsh-256/memo/[]3328752869_54_-..jdoc_showjshtooldoc_unzipintodir..+home+joey+j+tools_.memo
## Was this caused by the []s ?

## TODO: Allow user to specify two thresholds: one to try to clear past, another at which to warn user.
## TODO: What about prioritising which files are removed first?  What about allowing user to offer non-default reclaim directories?

## TODO: if del is really meant to be recoverable, reclaimspace should probably favour oldest deleted files, rather than deleting them in a random order.

## TODO: it would be good (if there aren't too many files in /RECLAIM) to order files by last-accessed time, and delete the longest-unaccessed files first.

## SAFETY:  Don't be scared; look below.  The two rm and rmdir commands both have /RECLAIM/ hardwired into them.  Therefore they will never delete anything that isn't below a directory called RECLAIM (or "reclaim" on some fs).

## TOUBLESHOOTING: If you get "Stale NFS file handle" errors on your vfat filing system, you can ignore them by swapping "find . -type f" below for the "ls -R | ls-Rtofilelist | filesonly -inclinks" line.

## Rare danger of infinite loop if somehow rm -f repeatedly succeeds but does not reduce disk usage, or the number of files in RECLAIM/ .
## DONE: so that reclaimspace may be run regularly from cron, put in a max loop threshold to catch that condition.
## OK but this doesn't deal with the case when rm blocks for unhealthy system reasons.  So my cron line for relcaimspace now has a findjob check.

## This didn't work when if test -f "$FILE" hadn't quotes on a spaced file.
# set -e

## Fri Jun 15 15:00:36 BST 2007: That's fucking hilarious.  I'm working on my latest most stable version of reclaimspace, and I've run out of diskspace.  :P

if [ "$1" = --help ]
then

	echo
	echo "reclaimspace [ <mount_regexp> ]"
	echo
	echo "  is intended to be run regularly as root, but can be run from the cmdline."
	echo "  It scans all partitions (meeting the regexp if given),"
	echo "  and on those for which free space deceeds MINKBYTES [default=102400 (100Meg)],"
	echo "  it tries to remove files from the partition's /RECLAIM directory."
	echo "  You can also now export MINMEG=200 for example, to ensure 200 meg left free."
	echo
	echo "Setup:"
	echo
	echo "  Create a /RECLAIM directory in each of your partition's root directories."
	echo "  Also: chmod ugo+w <each_reclaim_dir>"
	echo "  Add to root's crontab:"
	echo "    0-59/4 * * * *  /home/joey/j/jsh reclaimspace > /tmp/reclaimspace.log"
	echo
	echo "  Then users can use jsh's del command to delete files.  [TODO: overlap bug!]"
	echo "  Each file will be moved to the /RECLAIM directory of its partition." # (if it exists)
	echo "  Then, once less than MINKBYTES of space if available on a partition,"
	echo "  reclaimspace running from crontab will start deleting RECLAIMable files."
	echo
	# echo "Note:  This system is irrevocably laggy, because it depends on cron."
	# echo "       If you create a huge file very quickly, eg. with dd, reclaimspace"
	# echo "       from cron will probably not clear space in time for you,"
	# echo "       although it /might/ if you run reclaimspace from the cmdline at the same time."
	# echo
	exit 1

fi

[ "$MINMEG" ] && MINKBYTES=$((MINMEG*1024))
# export MINKBYTES=10240 ## 10Meg
[ "$MINKBYTES" ] || export MINKBYTES=102400 ## 100Meg

SELECTIONREGEXP="$1"

# date

## TODO: determine whether mount is ro, and if so skip it.

## FIXED: the old version doesn't recognise when there is low space but nothing to reclaim, because the find is empty the inner loop is never called

## DONE: There is some situation whereby the -lt test complains: 100%: integer expression expected
##       Ah yes this is when a really long device (eg. a file) is used, and the numbers drop to the next line!
##       The solution would be to join each line containing no spaces to the next line.  Although this (in fact the script anyway) would have trouble if the filename/device contains spaces.
##       Dodgy hack factored out to flatdf.  OK better solution now with spaceon function.

## DONE: rather than a dependency on this dirty external flatdf,
##       we should re-run df for each device of interest,
## DONE: rather than a dependency on this dirty external flatdf,
##       we should re-run df for each device of interest,
##       and use tail -1 and a sed which doesn't mind missing initial filename
##       (cos it could be one before the last line) to get the usage numbers.

# flatdf 2>/dev/null | drop 1 |
# takecols 1 4 6 |
# grep -v "/cdr" |
# # pipeboth |
# while read DEVICE SPACE MNTPNT
# do

## Like flatdf but better - only works on one mountpoint at a time.
function spaceon() {
	MNTPNT="$1"
	SPACE=`
		df "$MNTPNT" |
		## This ensures that if the line overflowed (eg. because the device was a long filename), we drop the file line and get only the stats line:
		tail -n 1 |
		## This extracts the available space field, whether the file/device was dropped or not:
		sed 's+^[^ 	]*[ 	]*[^ 	]*[ 	]*[^ 	]*[ 	]*\([^ 	]*\).*+\1+'
	`
	echo "$SPACE"
}

function reclaimfrom() {

	MNTPNT="$1"
	# reclaimDir="$MNTPNT/RECLAIM"
	## We don't use "$reclaimDir" - like a nutter we hard-code "$MNTPNT"/RECLAIM every time, "for safety".

	## Moving this find outside of the conditional while has made it more efficient (without memo) when many files need reclaiming, but very inefficient when 0 files need reclaiming.
	## Ideally we wouldn't do this if we check before and space is ok.
	# if [ -d "$MNTPNT/RECLAIM" ] && [ "$SPACE" -lt "$MINKBYTES" ] && cd "$MNTPNT/RECLAIM"
	## I was using this mode for debug purposes:
	if [ -d "$MNTPNT/RECLAIM" ] && cd "$MNTPNT/RECLAIM"
	# if [ -d "$MNTPNT/RECLAIM" ] && cd "$MNTPNT/RECLAIM" && [ "$SPACE" -lt "$MINKBYTES" ]
	then

		## I had a lot of trouble if I broke out of the while loop, because the find was left dangling and still outputting (worse on Gentoo's bash).
		## I did try cat > /dev/null to cleanup the end of the stream, but if I had already passed, the cat caused everything to block!
		## So I decided it's easier (especially if the script might be modified in the future), that the while loop should read all of find's output,
		## but only act if low space requires it.
		## Why use 'find .' when we could be explicit?  Well "$MNTPNT"/RECLAIM does not work here; we need a relative path here because we do "$MNTPNT"/RECLAIM/"$FILE" later.
		nice -n 20 find . -type f |
		# ( randomorder && echo ) | ## need this end line otherwise read FILE on last entry ends the stream and hence the sh is killed. (?)
		# ( nice -n 20 find . -type f ; echo ; echo ; echo ) |
		## After huge changes it turns out it was only the 20 that was the problem on Gentoo; 10 seems ok.
		## This find | the rest means the rest never gets done if there are no files.
		# nice -n 10 find . -type f |
		## Oh dear: find was encountering "Stale NFS file handle" error and breaking out instead of continuing.
		## This does better although it has two dependencies so find is preferable on non-symptomatic systems:
		## But: This find can run really slow if your are on a busy system and/or . has many files and subdirs.  At least now it only runs when reclamation is needed.
		## So testing: Possible solution: find | head -n 1000 might SIGHUP the find or otherwise stop it once 1000 lines have been produced.  =)  Try it the next time the problem is encountered...
		# nice -n 10 find-typef_avoiding_stale_handle_error . |            ## works but skips links :/
		# nice -n 10 'ls' -a -R | ls-Rtofilelist | filesonly -inclinks |   ## works ok
		head -n 1000 | ## since that is the timeout/max we do below

		# ( ## This sub-clause is needed so that the cat can send the rest of the randomorder stream somwhere, other bash under gentoo complains about a "Broken pipe"

		## I can't get set -e to work on these tests; because they are in while loop?  Ah they do now I've reduced the ()s.
		while read FILE && [ "$SPACE" -lt "$MINKBYTES" ]
		do

			## Never reached if there was no more stream to read files from:
			# export DEBUG=true
			[ "$DEBUG" ] && debug "$FILE"

			ATTEMPTSMADE=`expr "$ATTEMPTSMADE" + 1`
			if [ "$ATTEMPTSMADE" -gt 999 ]
			then
				## BUG: of course this can be reached legitimately before the work is done if the reclaim dir is full of many small or empty files.
				error "Stopping on \"timeout\" reclamation attempt # $ATTEMPTSMADE."
				## TODO: should we really timeout all?  Wouldn't it be better to timeout this partition, but proceed to rest?
				exit 12
			fi

			# echo "Partition $DEVICE mounted at $MNTPNT has $SPACE"k" < $MINKBYTES"k" of space."

			REMOVED=
			if [ -f "$MNTPNT"/RECLAIM/"$FILE" ] || [ -L "$MNTPNT"/RECLAIM/"$FILE" ] ## working file or symlink to folder or broken symlink
			then

				## Under Linux, rm-ing a file which a process is still writing to, can leave the disk-space unreclaimed, until that process actually lets go of the file handle.
				## We can force the data to be reclaimed immediately, by emptying the file before deleting it (e.g. using printf "" > $file).
				## NOTE!  We should never do this if the file is a symlink!  The link may be pointing to a file outside the RECLAIM dir, but even if it is inside, really our current task is just to remove the link, not to destroy its target!
				## This check is done by issymlink.  NOTE issymlink must correctly recognise both working and *broken* symlinks, since we don't want to printf "" into either.
				## NOTE!  We should never do this if the file is a hardlink!  Hard links are costly to detect.  Empying one file will empty the other.
				## DISABLED PERMANENTLY due to serious hardlink danger.
				# if ! issymlink "$MNTPNT"/RECLAIM/"$FILE"
				# then
					# echo "${COLRED}${COLBOLD}Emptying:${COLRESET} printf '' > $MNTPNT"/RECLAIM/"$FILE"
					# printf '' > "$MNTPNT"/RECLAIM/"$FILE"
				# fi
				## The better solution, where possible, is of course to close the process which is writing to the file.
				## The real annoyance is that, whilst this feature is rarely needed, if the user *does* need it, it cannot be applied retrospectively; once we have rm-ed the file handle, we cannot empty that file afterwards, if it is still using disk-space!

				echo "${COLRED}${COLBOLD}Reclaiming:${COLRESET} rm -f $MNTPNT"/RECLAIM/"$FILE"
				## Now we need to turn set -e off!
				# set +e
				if rm -f "$MNTPNT"/RECLAIM/"$FILE"
				then
					REMOVED=true
					## TODO: refactor this so /RECLAIM/ is hardwired into rmdir line:
					DIR=`dirname "$MNTPNT"/RECLAIM/"$FILE"`
					rmdir -p "$DIR" 2>/dev/null
					## TODO: problem, if done as root, and /RECLAIM is empty, this might remove the /RECLAIM directory itself!
					## Well, here's a fix:!
					mkdir -p "$MNTPNT"/RECLAIM ## Remake the /RECLAIM dir just in case it was deleted.
				fi
				# set -e
			fi

			# SPACE=`flatdf | grep "^$DEVICE[ 	]" | takecols 4`
			SPACE=`spaceon "$MNTPNT"` ## Like flatdf but better - only works on one mountpoint at a time.
			echo "Space increased to: $SPACE"

			if [ -z "$REMOVED" ]
			then
				## Actually this doesn't get run if the partition has no files to reclaim.  I believe the read FILE above causes a breakout when it tries to read past end of stream.
				echo "But I failed to reclaim: $FILE"
				## When two reclaimspace's are running, the reclamation of $FILE
				## by the other will cause this one to skip the partition.
				## No problem; two shouldn't really be running simultaneously anyway.
			fi

		done

		## Check/summarise:
		# find "$MNTPNT"/RECLAIM/ -type d | grep -v "^\.$" |
		verbosely find "$MNTPNT"/RECLAIM/ -type d | grep -v "/$" |
		reverse |
		# catwithprogress |
		verbosely foreachdo rmdir 2>&1 |
		# grep -v "^rmdir: failed to remove '.*': Directory not empty$"
		grep -v "Directory not empty"



		## Recently(?) problems developed with this approach.  What if the last read reached end-of-stream?  Then cat probably blocks!
		## Failed attempt solving with the echo above, so that loop will break out before reading EOS so we can read it here.
		# cat > /dev/null
		## So now we do it inside the loop.

		echo " done $DEVICE $MNTPNT ($SPACE"k")"

		# )

	else
		echo "Could not cd to reclaim dir: $MNTPNT/RECLAIM" >&2
	fi

	echo

}


mount |
## If you are chrooted, but /proc has been mounted, this works much better (well it works!):
# cat /proc/mounts |

grep "^/dev" |

grep "$SELECTIONREGEXP" |

grep -v " (\<ro\>.*)$" | ## Excludes CD-drives and other read-only mounts
grep -v "(.*bind.*)$" |

takecols 1 3 |

# grep -v "/dev$" |
# grep -v "/dev/pts$" |

while read DEVICE MNTPNT
do

	# SPACE=`flatdf | grep "^$DEVICE[ 	]" | takecols 4`
	## TODO: the following method is duplicated below; should be migrated into flatdf.
	SPACE=`spaceon "$MNTPNT"` ## Like flatdf but better - only works on one mountpoint at a time.
	## But since we grep "^dev", we don't tend to get an overflowing field 1 anyway!
	# SPACE=`df "$MNTPNT" | takecols 4`

	# echo "Checking space on $DEVICE $MNTPNT $SPACE"k
	# echo "[reclaimspace]  $MNTPNT     $SPACE"k
	# echo "[reclaimspace]	$MNTPNT	$((SPACE/1024))"M | expand -t 20

	ATTEMPTSMADE=0

	# [ -d "$MNTPNT"/RECLAIM ] && cd "$MNTPNT"/RECLAIM && find . -type f | countlines

	if [ -n "$SPACE" ] && [ "$SPACE" -lt "$MINKBYTES" ]
	then

		jshwarn "Partition $DEVICE mounted at $MNTPNT has $SPACE"k" < $MINKBYTES"k" of space."

		reclaimfrom "$MNTPNT"

	fi

done
