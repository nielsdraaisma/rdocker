#!/usr/bin/env bash
# $1 => Build target : user@host
# $2 => full docker command, including options "-e FOO=bar run"
randomBuildDir="/tmp/$RANDOM"
rsync -Ra . $1:$randomBuildDir
scp .dockercfg $1:.dockercfg
ssh $1 docker $2
ssh $1 rm -Rf $randomBuildDir