#!/bin/bash

set -e

basedir=$(dirname $0)
docdir=$basedir
files=$(find $basedir/lib -name "*-test.mu")
awkfile=$basedir/muon-clj/clj-to-md.awk

for file in $files; do
    target=$docdir/$(basename $file -test.mu).md
    grep "^;; #" $file | sed "s/#/  /g" | sed "s/;;    \( *\)/\1* /" | perl -p -e "s/[*] (.*)/* [\1](#\L\1)/" | perl -p -e "s/(#[^ ]*) /\1-/g" | perl -p -e "s/(-[^ ]*) /\1-/g" | perl -p -e "s/(-[^ ]*) /\1-/g" | perl -p -e "s/(-[^ ]*) /\1-/g" > .tmp
    awk -f $awkfile $file >> .tmp
    mv .tmp $target
done
