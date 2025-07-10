#!/bin/bash

docker build . -t iacm-migration

docker run -it -v $(dirname $0)/workspaces:/app/workspaces -v $(dirname $0)/configs:/app/configs --env-file .env iacm-migration /app/script.sh $1
