#!/usr/bin/env bash
REMOTE_DIR="/tmp/$RANDOM"
if [ -f "id_rsa" ]; then
	SSH_KEY_OPT="-i id_rsa"
	RSYNC_SSH_OPTS="-e 'ssh $SSH_KEY_OPT -C -c blowfish'"
fi
if [ -f ".dockercfg" ]; then
	echo "Uploading .dockercfg file"
	UPDATE_RESULT=scp $SSH_KEY_OPT $BUILD_USER@$BUILD_HOST:.dockercfg
	echo $UPDATE_RESULT
	echo "Done : $UPDATE_RESULT"
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