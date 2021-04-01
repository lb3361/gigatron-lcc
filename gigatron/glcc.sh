#!/bin/sh

progname="`basename $0`"
if [ "$progname" != "$0" ]
then
    # programname contains directory components
    progdir="`dirname $0`"
else
    # must search along path
    tmpvar="$PATH"
    while [ -n "$tmpvar" ]
    do
      IFS=':' read progdir tmpvar <<EOF
$tmpvar
EOF
      test -x "$progdir/$progname" && break
    done
fi

progdir=`cd $progdir ; pwd`
while [ -L "$progdir/$progname" ]
do
    tmpvar=`ls -ld $progdir/$progname`
    tmpvar=`expr "$tmpvar" : '.*-> *\(.*\)'`
    progname=`basename $tmpvar` 
    tmpvar=`dirname $tmpvar` 
    progdir=`cd $progdir ; cd $tmpvar ; pwd` 
done


progname="lcc"

if [ ! -x "$progdir/lcc" ]
then
   echo 1>&2 "$progdir/lcc: command not found"
   exit 10
fi

LCCDIR="$progdir" exec "$progdir/lcc" "$@"
