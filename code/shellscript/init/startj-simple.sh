## Try to guess the top directory of j install
## If all below fails, then you should set it youself with export JPATH=...; source $JPATH/startj
if test ! $JPATH; then
	if test -d "$HOME/j"; then
		export JPATH=$HOME/j
	## This doesn't work: bash cannot see it unless we call startj direct (no source)
	elif test -d `dirname "$0"`; then
		export JPATH=`dirname "$0"`
		echo "startj: guessed JPATH=$JPATH"
	else
		echo "startj: Could not find JPATH. Not starting."
		# env > /tmp/env.out
		exit 0
	fi
fi
export PATH=$JPATH/tools:$PATH

. javainit
. hugsinit