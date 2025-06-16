ACCOUNT=hrak
APP_NAME=kube-latency

PACKAGE_NAME=github.com/${ACCOUNT}/${APP_NAME}
GO_VERSION=1.24

DOCKER_IMAGE=${ACCOUNT}/${APP_NAME}
DOCKER_TAG=latest
BUILD_DIR=_build

CONTAINER_DIR=/go/src/${PACKAGE_NAME}

.PHONY: version

all: build

depend:
	rm -rf ${BUILD_DIR}/
	mkdir $(BUILD_DIR)/

version:
	$(eval GIT_STATE := $(shell if test -z "`git status --porcelain 2> /dev/null`"; then echo "clean"; else echo "dirty"; fi))
	$(eval GIT_COMMIT := $(shell git rev-parse HEAD))
	$(eval APP_VERSION := $(shell cat VERSION))

fmt: ## Run go fmt against code.
	go fmt ./...

vet: ## Run go vet against code.
	go vet ./...

build: depend version fmt vet
	CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build \
		-a -tags netgo \
		-o ${BUILD_DIR}/${APP_NAME}-linux-amd64 \
		-ldflags "-X main.AppGitState=${GIT_STATE} -X main.AppGitCommit=${GIT_COMMIT} -X main.AppVersion=${APP_VERSION}"

docker-build: version
	docker build --build-arg GIT_COMMIT=$(GIT_COMMIT) --build-arg GIT_STATE=$(GIT_STATE) --build-arg APP_VERSION=$(APP_VERSION) -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	
docker-push:
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

vendor-update:
	go mod tidy -compat=1.24
	go mod vendor
