# sed "s|$*\(.*\)|\2|"

# This is actually afterfirstall !

while read X; do
  Y=`echo "$X" | sed "s|$*.*||"`
  # echo "y=$Y"
  echo "$X" | sed "s|^$Y$*||"
done

# Problem is sed doesn't do non-greedy matching
# need context, but at this level of abstraction we need to ensure
# .* does not match do "$*"
# sed "s+$*.*++"
# Untested.  I expect it gets only the first argument!
# tr "\n" " " | awk ' BEGIN { FS="'"$1"'" } { printf($2"\n") } '

# OK here we use greedy matching on the right hand side
# and using awk, extract the text which matched the RE.

# awk '
  # BEGIN {
    # SRCHLEN=length("'"$*"'");
  # }
  # function extract(s,re) {
    # match(s,re);
    # return substr(s,RSTART+SRCHLEN,RLENGTH-SRCHLEN);
  # }
  # {
    # for ( s=$0 ; t = extract(s,"'"$*.*"'") ; s = substr(s,RSTART+RLENGTH) )
      # print t;
  # }
# '
