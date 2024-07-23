#!/bin/bash -e

if [ $ARG_DEBUG != "false" ]; then
	set -x
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/utils.sh"

echo "Cloning and checking out $ARG_REPOSITORY:$ARG_BRANCH in $ARG_CHECKOUT_LOCATION"

mkdir -p "$ARG_CHECKOUT_LOCATION"
cd "$ARG_CHECKOUT_LOCATION"

__mutex_queue_file=mutex_queue
__repo_url="https://x-access-token:$ARG_REPO_TOKEN@$ARG_GITHUB_SERVER/$ARG_REPOSITORY"
__ticket_id="$GITHUB_RUN_ID-$(date +%s)-$(( $RANDOM % 1000 ))"
# $GITHUB_STATE does NOT exist in the post-entry, so $GITHUB_WORKSPACE is used instead to share the info between entry and post-entry
# https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#sending-values-to-the-pre-and-post-actions
# https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions#runspre-entrypoint
# The file `.$GITHUB_RUN_ID-$ARG_BRANCH` is used to share the info between entry and post-entry
# As $GITHUB_RUN_ID doesn't exist in GitHub Action, 
# $ARG_BRANCH is used to concatenate to the file name to avoid the conflict between jobs in the same run
echo "ticket_id=$__ticket_id" > "$GITHUB_WORKSPACE/.$GITHUB_RUN_ID-$ARG_BRANCH"
cat "$GITHUB_WORKSPACE/.$GITHUB_RUN_ID-$ARG_BRANCH"

set_up_repo "$__repo_url"
enqueue $ARG_BRANCH $__mutex_queue_file $__ticket_id
wait_for_lock $ARG_BRANCH $__mutex_queue_file $__ticket_id $ARG_TIMEOUT

echo "Lock successfully acquired"

