#!/usr/bin/env bash
#
# Remote docker wrapper.
# Rsyncs current working directory onto the target and performs docker commands on remote host
# Env vars :
# RDOCKER_USER - userid on remote host
# RDOCKER_HOST - remote hostname
# RCODCKER_SYNC - If set rsyncs the entire project to a remote temp directory
# - All other arguments are passed onto the remote docker command.
# - If the first argument is 'build' the entire local directory is rsynced and used as build directory
if [ -z "${RDOCKER_USER}" ]; then 
	echo "Env var RDOCKER_USER not specified";
	exit 1
fi
if [ -z "${RDOCKER_HOST}" ]; then 
	echo "Env var RDOCKER_HOST not specified";
	exit 1
fi
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
	scp $SSH_KEY_OPT .dockercfg $RDOCKER_USER@$RDOCKER_HOST:
	SCP_RESULT=$?
	if [ ! $SCP_RESULT -eq 0 ]; then
		echo "Failed to upload docker config"
		exit $SCP_RESULT
	fi
fi
if [ ! -z "${RDOCKER_SYNC}" ]; then 
	echo "Uploading project for docker command $1"
	rsync -rav --exclude=.git --delete $RSYNC_SSH_OPTS . $RDOCKER_USER@$RDOCKER_HOST:$REMOTE_DIR
	echo "Done"
	CD_COMMAND="cd $REMOTE_DIR; "
fi

REMOTE_COMMAND="$CD_COMMAND docker $@"
echo "Executing remote command : $RE"
ssh $SSH_KEY_OPT $RDOCKER_USER@$RDOCKER_HOST -t -t "$REMOTE_COMMAND"
BUILD_RESULT=$?
if [ -f ".dockercfg" ]; then
	echo "Deleting remote .dockercfg file"
	ssh $SSH_KEY_OPT $RDOCKER_USER@$RDOCKER_HOST "rm -Rf ~/.dockercfg $REMOTE_DIR"
	echo "Done"
fi
exit $BUILD_RESULT