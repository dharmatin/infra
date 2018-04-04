#!/usr/bin/env bash

set -ex

docker run --rm -v $(pwd):/opt/deployment -w /opt/deployment ${DOCKER_REGISTRY_URL} \
       ansible-playbook -i inventory/${ENVIRONMENT_INT}/${REGION_NAME}/inventory  -vvvv cleanup-stack.yml \
       -e version=${BUILD_NUMBER}