#!/usr/bin/env bash

muon_dir=$(dirname $BASH_SOURCE)
muon_clj_dir=$muon_dir/muon-clj
jar_url=https://brosenan-muon.s3.eu-west-1.amazonaws.com/muon-clj-0.1.0-SNAPSHOT-standalone.jar
jar_path=$muon_clj_dir/target/uberjar

mkdir -p $jar_path
(cd $jar_path; curl $jar_url -O)

echo export PATH=\$PATH:$PWD >> ~/.bashrc

echo Muon installed. Enter an new bash shell and try: muon --help
