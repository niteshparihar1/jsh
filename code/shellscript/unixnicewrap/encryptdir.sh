NOTAR=
if test "$1" = "-notar"
then
	NOTAR=true
	shift
fi

DIR="$1"
FILE="$DIR.tgz.encrypted"

test -f "$FILE" &&
mv "$FILE" "$FILE.bak"

touch "$FILE"
chmod 600 "$FILE"

if test "$NOTAR"
then
	cat "$DIR"
else
	tar cz "$DIR"
fi |
gpg -r "Paul Clark <pclark@cs.bris.ac.uk>" -e > "$FILE"
