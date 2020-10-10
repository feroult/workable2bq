#!/bin/bash

PORT=8080

docker run -it -v $(pwd):/app \
    -e PORT=$PORT \
    -e WORKABLE_TOKEN=$WORKABLE_TOKEN \
    -e WORKABLE_DOMAIN=$WORKABLE_DOMAIN \
    -e BUCKET_NAME=$BUCKET_NAME \
    -v $HOME/.config/gcloud:/root/.config/gcloud \
    -p 127.0.0.1:$PORT:$PORT/tcp \
    workable $1
