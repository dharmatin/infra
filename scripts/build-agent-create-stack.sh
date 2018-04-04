#!/usr/bin/env bash

set -ex

docker run --rm -v $(pwd):/opt/deployment -w /opt/deployment ${DOCKER_REGISTRY_URL} \
       ansible-playbook -i inventory/${ENVIRONMENT_INT}/${REGION_NAME}/inventory -vvvv buildkite-agent.yml \
       -e version=${BUILD_NUMBER}-${BUILDKITE_BUILD_ECR} \
       -e buildkite_build_ecr=${BUILDKITE_BUILD_ECR}