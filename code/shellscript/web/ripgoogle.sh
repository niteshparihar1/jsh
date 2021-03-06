#!/bin/zsh

DESTIMGFILE=googlerip.jpg
LEFTIMGFILE=googleripleft.jpg
RIGHTIMGFILE=googleripright.jpg

mkdir -p $HOME/.ripgoogle
cd $HOME/.ripgoogle

wget -N www.google.com

HREF=`
	cat index.html |
	grep -i "img" | grep -i "src=" | grep -i "href=" |
	head -n 1 |
	afterfirst "href=" |
	between '\"' |
	head -n 1
`
HREF=`tourl "$HREF" "www.google.com"`
if test ! "$?" = 0
then
	echo "Failed to find link from main image."
	HREF=""
fi
echo "Got href=>$HREF<"

################################################################################
## Get image and split into two:

IMG=`
	cat index.html |
	grep -i img | head -n 1 |
	afterfirst img | afterfirst IMG | afterfirst src= | beforefirst " " |
	tr -d '"'
`
IMGURL="http://www.google.com/$IMG"
IMGURL=`echo "$IMGURL" | tr -s '/' | sed 's+/+//+'`
[ "$DEBUG" ] && debug "IMGURL=$IMGURL"
IMGFILE="www.google.com/$IMG"
[ "$DEBUG" ] && debug "IMGFILE=$IMGFILE"
echo "Getting image >$IMGURL<"
## Why do -x and -N options result in 404?!  What's different about http of former?!
wget -N -x "$IMGURL"
# IMGFILE=`echo "$IMG" | afterlast /`
echo "Got image=>$IMGFILE<"

convert $IMGFILE -geometry 60 -quality 100 $DESTIMGFILE
IMGSIZE=`imagesize $DESTIMGFILE`
IMGWIDTH=`echo $IMGSIZE | before "x"`
IMGHEIGHT=`echo $IMGSIZE | after "x"`
echo "Got image size=>$IMGWIDTH"x"$IMGHEIGHT<"

HALFIMGWIDTH=$[$IMGWIDTH/2];
HALFIMGWIDTHMAJ=$[$[$IMGWIDTH+1]/2];
IMGWIDTHPLUS=$[$IMGWIDTH+12];
convert $DESTIMGFILE -crop $HALFIMGWIDTH"x"$IMGHEIGHT+0+0 $LEFTIMGFILE
convert $DESTIMGFILE -crop $HALFIMGWIDTH"x"$IMGHEIGHT+$HALFIMGWIDTHMAJ+0 $RIGHTIMGFILE

[ "$DEBUG" ] && debug "IMGWIDTHPLUS=$IMGWIDTHPLUS"
[ "$DEBUG" ] && debug "LEFTIMGFILE=$LEFTIMGFILE"
[ "$DEBUG" ] && debug "HREF=$HREF"
[ "$DEBUG" ] && debug "RIGHTIMGFILE=$RIGHTIMGFILE"
# LINE='                <a href='$HREF'><img border="0" align="middle" src="'$DESTIMGFILE'"></a>'
LINE='                <td width="'"$IMGWIDTHPLUS"'" valign="middle" align="center"><a href="http://www.google.com/"><img alt="(Home)" border="0" align="middle" src="'"$LEFTIMGFILE"'"></a><a href="'"$HREF"'"><img alt="(Topical)" border="0" align="middle" src="'"$RIGHTIMGFILE"'"></a></td>'
[ "$DEBUG" ] && debug "LINE=$LINE"

## Need to escape &s because they have special meaning in sed replacement string.
LINE=`echo "$LINE" | sed 's+&+\\\\\&+g'`
cp $JPATH/org/jumpgate.html jumpgate-orig.html
cat jumpgate-orig.html | verbosely replaceline "<\!-- #~googleimage~# -->" "<\!-- #~googleimage~# -->$LINE" > finaljumpgate.html
# [ "$DEBUG" ] && debug "`cat finaljumpgate.html | grep googleimage`"

# Move the final files over the originals
cp finaljumpgate.html $JPATH/org/jumpgate.html
cp $LEFTIMGFILE $JPATH/org/
cp $RIGHTIMGFILE $JPATH/org/
# mv $DESTIMGFILE $JPATH/org/
