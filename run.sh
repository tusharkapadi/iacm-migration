#!/bin/bash

docker build . -t iacm-migration

docker run -it -v $(dirname $0)/workspaces:/app/workspaces --env-file .env iacm-migration
