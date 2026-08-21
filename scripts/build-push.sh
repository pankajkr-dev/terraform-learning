#!/bin/sh
set -eu

repository_url="$1"
tag="${2:-latest}"

aws ecr get-login-password --region "${AWS_DEFAULT_REGION}" | docker login --username AWS --password-stdin "${repository_url%/*}"
docker build --tag "${repository_url}:${tag}" .
docker push "${repository_url}:${tag}"
