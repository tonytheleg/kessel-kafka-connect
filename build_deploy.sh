set -exv

# check for podman or docker
DOCKER=$(command -v podman || command -v docker)

if [[ -z "$IMAGE" ]]; then
    IMAGE="quay.io/cloudservices/kessel-kafka-connect"
fi
IMAGE_TAG=$(git rev-parse --short=7 HEAD)
GIT_COMMIT=$(git rev-parse --short HEAD)
SECURITY_COMPLIANCE_TAG="sc-$(date +%Y%m%d)-$(git rev-parse --short=7 HEAD)"

if [[ -z "$QUAY_USER" || -z "$QUAY_TOKEN" ]]; then
    echo "QUAY_USER and QUAY_TOKEN must be set"
    exit 1
fi

if [[ -z "$RH_REGISTRY_USER" || -z "$RH_REGISTRY_TOKEN" ]]; then
    echo "RH_REGISTRY_USER and RH_REGISTRY_TOKEN  must be set"
    exit 1
fi

# Create tmp dir to store data in during job run (do NOT store in $WORKSPACE)
export TMP_JOB_DIR=$(mktemp -d -p "$HOME" -t "jenkins-${JOB_NAME}-${BUILD_NUMBER}-XXXXXX")
echo "job tmp dir location: $TMP_JOB_DIR"

function job_cleanup() {
    echo "cleaning up job tmp dir: $TMP_JOB_DIR"
    rm -fr $TMP_JOB_DIR
}

trap job_cleanup EXIT ERR SIGINT SIGTERM

DOCKER_CONF="$TMP_JOB_DIR/.docker"

mkdir -p "$DOCKER_CONF"
$DOCKER --config="$DOCKER_CONF" login -u="$QUAY_USER" -p="$QUAY_TOKEN" quay.io
$DOCKER --config="$DOCKER_CONF" login -u="$RH_REGISTRY_USER" -p="$RH_REGISTRY_TOKEN" registry.redhat.io
$DOCKER --config="$DOCKER_CONF" build --build-arg GIT_COMMIT=$GIT_COMMIT --no-cache -t "${IMAGE}:${IMAGE_TAG}" . -f ./Dockerfile

if [[ "$GIT_BRANCH" == "origin/security-compliance" ]]; then
    $DOCKER --config="$DOCKER_CONF" tag "${IMAGE}:${IMAGE_TAG}" "${IMAGE}:${SECURITY_COMPLIANCE_TAG}"
    $DOCKER --config="$DOCKER_CONF" push "${IMAGE}:${SECURITY_COMPLIANCE_TAG}"
else
    $DOCKER --config="$DOCKER_CONF" push "${IMAGE}:${IMAGE_TAG}"
    $DOCKER --config="$DOCKER_CONF" tag "${IMAGE}:${IMAGE_TAG}" "${IMAGE}:latest"
    $DOCKER --config="$DOCKER_CONF" push "${IMAGE}:latest"
fi
