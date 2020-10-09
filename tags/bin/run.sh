#!/bin/bash

docker run -it -v $(pwd):/app \
    -e WORKABLE_TOKEN=$WORKABLE_TOKEN \
    -e WORKABLE_DOMAIN=dextra \
    -v $HOME/.config/gcloud:/root/.config/gcloud \
    workable-tags bash
