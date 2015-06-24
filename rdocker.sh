#!/usr/bin/env bash
#
# Remote docker wrapper.
# Rsyncs current working directory onto the target and performs docker commands on remote host
# Env vars :
# RDOCKER_USER - userid on remote host
# RDOCKER_HOST - remote hostname
# RDOCKER_BUILD_PATH  - remote path to sync into
# RDOCKER_SYNC        - enabled/disable remote sync
# - All other arguments are passed onto the remote docker command.
# - If the first argument is 'build' the entire local directory is rsynced and used as build directory
if [ ! -z "${RDOCKER_DEBUG}" ]; then 
	set -x
	SSH_DEBUG_OPTS=" -v -v "
fi
if [ -z "${RDOCKER_USER}" ]; then 
	echo "Env var RDOCKER_USER not specified";
	exit 1
fi
if [ -z "${RDOCKER_HOST}" ]; then 
	echo "Env var RDOCKER_HOST not specified";
	exit 1
fi

echo "Starting remote docker build as ${RDOCKER_USER}@${RDOCKER_HOST}"

if [ -z "${RDOCKER_BUILD_PATH}" ]; then
	RDOCKER_BUILD_PATH="/tmp/$RANDOM$RANDOM"
fi

if [ -f "id_rsa" ]; then
	SSH_KEY_OPT="-i id_rsa"
	echo "found id_rsa file, using SSH option : $SSH_KEY_OPT"
fi

if [ -f ".dockercfg" ]; then
	echo "Uploading .dockercfg file"
	scp $SSH_KEY_OPT $SSH_DEBUG_OPTS .dockercfg $RDOCKER_USER@$RDOCKER_HOST:
	SCP_RESULT=$?
	if [ ! $SCP_RESULT -eq 0 ]; then
		echo "Failed to upload docker config"
		exit $SCP_RESULT
	fi
	echo "Done"
fi

if [ ! -z "${RDOCKER_SYNC}" ]; then 
	echo "Uploading project into $RDOCKER_BUILD_PATH"
	if [ ! -z "$SSH_KEY_OPT" ]; then
		rsync $SSH_DEBUG_OPTS -ra --exclude=.git --ignore=id_rsa --delete -e "ssh $SSH_KEY_OPT -C -c blowfish" . $RDOCKER_USER@$RDOCKER_HOST:$RDOCKER_BUILD_PATH
	else 
		rsync $SSH_DEBUG_OPTS -ra --exclude=.git --ignore=id_rsa --delete  . $RDOCKER_USER@$RDOCKER_HOST:$RDOCKER_BUILD_PATH
	fi
	echo "Done"
	CD_COMMAND="cd $RDOCKER_BUILD_PATH; "
fi

ssh $SSH_DEBUG_OPTS $SSH_KEY_OPT $RDOCKER_USER@$RDOCKER_HOST -t -t "$CD_COMMAND docker $@"
BUILD_RESULT=$?

if [ -f ".dockercfg" ]; then
	echo "Deleting remote .dockercfg file"
	ssh $SSH_DEBUG_OPTS $SSH_KEY_OPT $RDOCKER_USER@$RDOCKER_HOST "rm -Rf ~/.dockercfg $RDOCKER_BUILD_PATH"
	echo "Done"
fi

exit $BUILD_RESULT