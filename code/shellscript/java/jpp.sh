#!/bin/bash
# -C : don't discard comments
# -H : show files being #included
# -P : don't add #lines
MACRO_ARGS="-C -P"

# ## TODO: unfinished: these filters can add warnings or unhide hidden #ifdef's from various file formats
# ## we should detect file format, and add notice, and if user asks, filter to unhide.
# ## we will need to map "c++" "C" "cxx" etc to "c"
# c_notice () { java_notice }
# ## I think C can handle #ifdef's so no need to hide them so no need to unhide hidden ones
# c_filter () { cat }
# java_notice () { echo "/** This file was auto-generated by jpp.  You probably want to be editing $PPNAME instead. **/" }
# java_filter () { sed 's+^[ 	]*//#+#+' }
# html_notice () { echo "<!-- This file was auto-generated by jpp.  You probably want to be editing $PPNAME instead. -->" }
# html_filter () { sed 's+^[ 	]*<!-- \(#.*\) -->+\1 +' }

INCLUDES=""
while [ ! "$1" = "--" ] && [ ! "$1" = "" ]
do
	INCLUDES="$INCLUDES -imacros $1"
	shift
done

shift

if [ ! "$?" = 0 ] ## if shifting the -- failed
then
more << !

Usage: jpp [<macro_files...>] -- <jpp_files_to_compile...>

  will process each supplied file X.jpp file through the GCC C++ pre-processor,
  overwriting the file X.

  NO: that is desirable but untrue!  Output is on stdout - you must >"X" yourself.

  Any <macro_files> are included before the jpp file is processed.

  jpp can be used to perform #define macros and #ifdef blocks for Java, HTML,
  BASIC, UnrealScript, and other languages.

  The C++ Preprocessor can be very useful, e.g. to compile with all logging
  code entirely removed.  :)

Example usage:

  jpp "lib/common.lib" "lib/hidelogging.lib" -- "src/MyApp.java.jpp"

    would overwrite "src/MyApp.java"

Useful options to add to JPP_GCC_OPTS:

  -E -H
    show files being included.

  -D name
    Predefine name as a macro, with definition 1.

  -D name=definition
    Predefine macro.

  -I dir
    Add the directory dir to the list of directories to be searched for
    header files.

Example library macro:

  #ifdef LOGGING_ENABLED
    #define Log(str); System.out.println("" + str);
  #else
    #define Log(str); 
  #fi

!
exit 2
fi

## If we actually got no args

function hasExtension() {
	echo "$PPNAME" | grep "\.$1$" >/dev/null
}

for PPNAME
do

	# if echo "$PPNAME" | grep "\.jpp$" >/dev/null
	# then
		# JNAME=`echo "$PPNAME" | sed 's+\.jpp++'`
	# else
		# ## Do common sensible conversions:
		# # JNAME=`echo "$PPNAME" | sed 's+\.jpp$+\.java+'` ## aah this overwrote when it wasn't .jpp!
		# ## Or add ".jpp":
		# JNAME=`echo "$PPNAME" | sed 's+$+.jpp+'` ## If it has .jpp it could remove it.  or we could ask as an option
	# fi
	(
		## TODO: different comment types, using [ "$COMMENTSTART" ] || COMMENTSTART="/**"
		comment="WARNING! This file was auto-generated by jpp.  You probably want to be editing $PPNAME instead."
		if hasExtension "html.jpp"
		then echo ; echo "<!-- $comment -->" ; echo
		elif hasExtension "\(java\|c\|C\|cpp\|cxx\|uc\|js\).jpp"
		then echo ; echo "/* $comment */" ; echo ## Stopped using /** ... **/ because strip_c_comments broke on it.
		elif hasExtension "bas"
		then echo ; echo "REM $comment" ; echo
		elif hasExtension "spp"
		then echo ; echo "; $comment" ; echo
		else echo ; echo "## $comment ##" ; echo
		fi
		## Pre-process:
		# gcc -x c Test.jpp -E $MACRO_ARGS -o - > Test.java
		## Pre-process using macros provided at command line:
		## Advantage: doesn't show include-file's contents =)
		verbosely gcc $JPP_GCC_OPTS -x c "$PPNAME" -E $MACRO_ARGS $INCLUDES -o -
	) # > "$JNAME"
## | grep -v "^# " > Test.java (sorted now thanks to gcc -P!)

	## Really we should collect these compiled filenames for one big compile at the end.
	# jikes "$JNAME"
	# javac Test.java

done

