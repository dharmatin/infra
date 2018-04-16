#!/usr/bin/env bash

set -ex

. ${PWD}/scripts/env.sh

docker run --rm -v $(pwd):/infra -w /infra ${DOCKER_REGISTRY_URL} \
       ansible-playbook -i inventory/${ENVIRONMENT_INT}/${REGION_NAME}/inventory -vvvv frontend-clean-stack.yml \
       -e new_stack_name=${STACK_NAME}
