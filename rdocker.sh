#!/usr/bin/env bash
#
# Remote docker wrapper.
# Rsyncs current working directory onto the target and performs docker commands on remote host
# Env vars :
# BUILD_USER - userid on remote host
# BUILD_HOST - remote hostname
# 
# - All other arguments are passed onto the remote docker command.
# - If the first argument is 'build' the entire local directory is rsynced and used as build directory
REMOTE_DIR="/tmp/$RANDOM"
if [ -f "id_rsa" ]; then
	echo "Using given id_rsa key file"
	SSH_KEY_OPT="-i id_rsa"
	RSYNC_SSH_OPTS="-e 'ssh $SSH_KEY_OPT -C -c blowfish'"
	echo "Using SSH option : $SSH_KEY_OPT"
	echo "Using rsync options : $RSYNC_SSH_OPTS"
fi
if [ -f ".dockercfg" ]; then
	echo "Uploading .dockercfg file"
	scp $SSH_KEY_OPT .dockercfg $BUILD_USER@$BUILD_HOST:
	SCP_RESULT=$?
	if [ ! $SCP_RESULT -eq 0 ]; then
		echo "Failed to upload docker config"
		exit $SCP_RESULT
	fi
fi
if [ $1 == "build" ]; then 
	echo "Uploading project for docker command $1"
	rsync -rav --exclude=.git --delete $RSYNC_SSH_OPTS . $BUILD_USER@$BUILD_HOST:$REMOTE_DIR
	echo "Done"
	CD_COMMAND="cd $REMOTE_DIR; "
fi
ssh $SSH_KEY_OPT $BUILD_USER@$BUILD_HOST -t -t "$CD_COMMAND docker $@"
BUILD_RESULT=$?
if [ -f ".dockercfg" ]; then
	echo "Deleting remote .dockercfg file"
	ssh $SSH_KEY_OPT $BUILD_USER@$BUILD_HOST "rm -Rf ~/.dockercfg $REMOTE_DIR"
	echo "Done"
fi
exit $BUILD_RESULT