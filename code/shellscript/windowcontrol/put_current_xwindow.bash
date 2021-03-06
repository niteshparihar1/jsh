#!/bin/dash
# jsh-ext-depends: xdotool xwininfo sed cut xdpyinfo

## Moves your current window to corner/edge/center of screen.
## Provide one of these as the argument:
## nw,top,ne,left,center,right,sw,bottom,se,center_x,center_y

## BUG: It doesn't move the mouse pointer; in Fluxbox this might mean that your
## focus will switch to the window now under the pointer.

## Config:
[ "$put_xwindow_padding" ] || put_xwindow_padding=5

putWhere="$1"

winid=`xdotool getwindowfocus`

[ "$winid" ] || . errorexit "xdotool failed to find current window."

# geometry=`xwininfo -id "$winid" | grep geometry | sed 's+.* ++'`
# echo "$geometry" | extractregex "[0-9][0-9]*" |
# (
	# read width
	# read height
	# read left
	# read top
	# # ...
# )

## The -geometry 131x37-6-7 sometimes has hinting,
## so we get the x/y/width/height a different way:
xwininfo=`xwininfo -id "$winid"`
extract_window_property () {
	printf "%s" "$xwininfo" | grep "^  $1: " | sed 's+.*: *++'
}
width=`extract_window_property "Width"`
height=`extract_window_property "Height"`
left=`extract_window_property "Absolute upper-left X"`
top=`extract_window_property "Absolute upper-left Y"`
xoffset=`extract_window_property "Relative upper-left X"`
yoffset=`extract_window_property "Relative upper-left Y"`

[ "$winid" ] || . errorexit "xdotool failed to get window size."

# width=`echo "$geometry" | sed 's/\([0-9]*\)x\([0-9]*\)+.*/\1/'`

oldwidth="$width" ; oldheight="$height"
[ "$width" -lt 80 ] && width=$(( $width * 8 )) && height=$(( $height * 8 ))

# scrwidth="`getxwindimensions | cut -d x -f 1`"
# scrheight="`getxwindimensions | cut -d x -f 2`"
xwindimensions=`xdpyinfo | grep dimensions: | sed 's+.*dimensions:[ ]*++ ; s+ .*++'`
scrwidth="`echo "$xwindimensions" | cut -d x -f 1`"
scrheight="`echo "$xwindimensions" | cut -d x -f 2`"

## "Unchanged" positions:
left=$(( $left - $xoffset ))
top=$(( $top - $yoffset ))

push_left () {
	left=$put_xwindow_padding
}
push_right () {
	left=$(( $scrwidth - $width - $xoffset - $put_xwindow_padding ))
}
push_top () {
	top=$put_xwindow_padding
}
push_bottom () {
	top=$(( $scrheight - $height - $yoffset - $put_xwindow_padding - 8 ))
	## For some reason we need an extra -8 here
	## This may mean we need an extra -4 for centrey.
}
push_centerx () {
	left=$(( $scrwidth / 2 - $width / 2 - $xoffset ))
}
push_centery () {
	top=$(( $scrheight / 2 - $height / 2 - $yoffset ))
}

case "$putWhere" in
	nw)
		push_left ; push_top
	;;
	top)
		push_top
		push_centerx
	;;
	ne)
		push_top
		push_right
	;;
	left)
		push_left
		push_centery
	;;
	center_x)
		push_centerx
	;;
	center_y)
		push_centery
	;;
	center)
		push_centerx
		push_centery
	;;
	right)
		push_right
		push_centery
	;;
	sw)
		push_left ; push_bottom
	;;
	bottom)
		push_bottom
		push_centerx
	;;
	se)
		push_right ; push_bottom
	;;
	*)
		echo "put_current_xwindow: do not recognise position \"$putWhere\"" >&2
		exit 3
	;;
esac

# wmctrl -r :ACTIVE: -e "1,$left,$top,$width,$height"
xdotool windowmove "$winid" "$left" "$top"

# ...

