#!/bin/sh
# #!/bin/sh

START=$1
END=$2
INC="1";
if test "$3" = "by"; then
	INC="$4"
fi

seq $START $INC $END

# X=$START
# LIST=""
# DONE=""
# while [ ! "$X" = "$END" ]; do
  # # LIST="$LIST$X "
  # echo "$X"
  # X=$[$X+$INC]
  # # X=$[$X+1]
# done
# echo $END
# # LIST="$LIST$END"
# # echo "$LIST"
