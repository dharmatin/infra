#!/usr/bin/env bash

set -ex


. ${PWD}/scripts/env.sh

docker run --rm -v $(pwd):/opt/deployment -w /opt/deployment ${DOCKER_REGISTRY_URL} \
       ansible-playbook -i inventory/${ENVIRONMENT_INT}/${REGION_NAME}/inventory frontend-alb.yml \
       -e version="${VERSION}" \
       -e buildkite_build_ecr="${BUILDKITE_BUILD_ECR}" \
       -vvvv