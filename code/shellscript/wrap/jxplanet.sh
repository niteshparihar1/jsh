# In 256 colour mode xplanet does rubbish dithering:
# xplanet -root -projection orthographic -body Earth -blend &
# So instead we force it to render outside X and dither with xv ...
# ( env DISPLAY= xplanet -output $JPATH/background.jpg -projection orthographic -body Earth -blend -geometry 1024x768 &&
#   xv -root -rmode 5 -maxpect -quit $JPATH/background.jpg )

cd /home/joey/planet_images

if test "$1" = "getclouds"; then

  DATE=`date`
  echo "$DATE: getting clouds" >> $JPATH/logs/jxplanet.txt

	FAVEARTHIMG="/usr/share/celestia/textures/earth.jpg"
  CLIMG="clouds_2000.jpg"
  XPID="/usr/share/xplanet/images/"
  MAPGEOM="2000x1000"
  export DISPLAY=""

  rm $CLIMG
  wget http://xplanet.sourceforge.net/$CLIMG
  touch $CLIMG

  xplanet -image $FAVEARTHIMG -cloud_image $CLIMG -shade 100 -output day-clouds.jpg -geometry $MAPGEOM
  xplanet -image $XPID/night.jpg -cloud_image $CLIMG -cloud_shade 30 -output night-clouds.jpg -geometry $MAPGEOM

elif test "$1" = "render"; then

  EXTRAARGS="$2 $3 $4 $5 $6 $7 $8 $9"
  if test ! "$JXPGEOM"; then
		JXPGEOM="1280x1024"
	fi

	ALLARGS="-label $EXTRAARGS -image day-clouds.jpg -night_image night-clouds.jpg -projection orthographic -blend -geometry $JXPGEOM -radius 45"

  nice -n 2 env DISPLAY= xplanet -dayside $ALLARGS -output $JPATH/background1.jpg
  xv -root -rmode 5 -maxpect -quit $JPATH/background1.jpg
	sleep 300
  nice -n 2 env DISPLAY= xplanet -nightside $ALLARGS -output $JPATH/background2.jpg
  nice -n 2 env DISPLAY= xplanet -moonside $ALLARGS -output $JPATH/background3.jpg
  nice -n 2 env DISPLAY= xplanet -random -markers $ALLARGS -output $JPATH/background4.jpg


else

  echo "jxplanet getclouds | render"
  exit 1

fi