#!/usr/bin/env bash

set -ex

. ${PWD}/scripts/env.sh

docker run --rm -v $(pwd):/opt/deployment -w /opt/deployment ${DOCKER_REGISTRY_URL} \
  ansible-playbook -i inventory/${ENVIRONMENT_INT}/${REGION_NAME}/inventory -vvvv frontend-alb-switch.yml \
  -e  new_stack_name=${STACK_NAME}
