#!/bin/bash

docker run -it -v $(pwd):/app \
    -e WORKABLE_TOKEN=$WORKABLE_TOKEN \
    -e WORKABLE_DOMAIN=$WORKABLE_DOMAIN \
    -v $HOME/.config/gcloud:/root/.config/gcloud \
    workable bash
