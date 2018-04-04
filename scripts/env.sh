#!/usr/bin/env bash

set -ex

echo '--- :house_with_garden: Check the environment here'

export PROD_AWS_ACCOUNT_ID=726150208279
export BUILD_NUMBER=${BUILDKITE_BUILD_NUMBER:=snapshot}
export AB=${ENV}
export APPLICATION="front-newlaunch-api"
export ENVIRONMENT=${ENV}
export ENVIRONMENT_INT=${ENV_INT}

if [[ -z "${BUILDKITE_BUILD_ECR}" ]]; then
  echo "Build number from parent pipeline is not passed check the BUILDKITE_BUILD_ECR variable ${BUILDKITE_BUILD_ECR}"
  exit 1
fi

case  $REGION  in
  'ap-southeast-1')
    export REGION_NAME='singapore'
    ;;
  'ap-northeast-1')
    export REGION_NAME='tokyo'
    ;;
  *)
esac

export DOCKER_REGISTRY_URL="${PROD_AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/deployer:latest"

eval $(docker run --rm xueshanf/awscli aws ecr get-login --no-include-email --registry-ids $PROD_AWS_ACCOUNT_ID --region $REGION)

export VERSION="${BUILDKITE_BUILD_ECR}-${BUILD_NUMBER}"
export STACK_NAME="${APPLICATION}-${AB}-${VERSION}"

