#!/bin/bash

echo "Starting action"

eval "$(ssh-agent -s)"

echo "Setting up SSH"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo -e "$DOKKU_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-keyscan "$HOST" >> ~/.ssh/known_hosts

cd "$GITHUB_WORKSPACE" || exit

DEFAULT_BRANCH=${DEFAULT_BRANCH:-$GITHUB_PRIMARY_BRANCH}
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ $CURRENT_BRANCH == "$DEFAULT_BRANCH" && -n $DOMAIN ]]; then
    APP_NAME=$DOMAIN
else
    APP_NAME=${CURRENT_BRANCH/\//-}
fi

echo "APP_NAME defined as $APP_NAME"

echo "Checking if app exists"
if ! ssh "dokku@$HOST -p $PORT dokku apps:exists $APP_NAME"; then
    echo "The app does not exist yet, creating the app"
    ssh "dokku@$HOST -p $PORT dokku apps:create $APP_NAME"
fi

echo "Deploying to host: $HOST"
git fetch --unshallow
git remote add "$APP_NAME" "dokku@$HOST:$APP_NAME"
git push -f "$APP_NAME" "$CURRENT_BRANCH:master"
echo "done... thank you"