#!/bin/sh
set -eu

mkdir -p /app/generated /app/node_modules
chown -R node:node /app/generated /app/node_modules

exec gosu node "$@"
