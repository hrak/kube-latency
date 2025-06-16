ACCOUNT=hrak
APP_NAME=kube-latency

DOCKER_IMAGE=${ACCOUNT}/${APP_NAME}
DOCKER_TAG=latest

.PHONY: version

all: build

version:
	$(eval GIT_STATE := $(shell if test -z "`git status --porcelain 2> /dev/null`"; then echo "clean"; else echo "dirty"; fi))
	$(eval GIT_COMMIT := $(shell git rev-parse HEAD))
	$(eval APP_VERSION := $(shell cat VERSION))

fmt: ## Run go fmt against code.
	go fmt ./...

vet: ## Run go vet against code.
	go vet ./...

build: version fmt vet
	CGO_ENABLED=0 go build \
		-a -tags netgo \
		-o bin/${APP_NAME} \
		-ldflags "-X main.AppGitState=${GIT_STATE} -X main.AppGitCommit=${GIT_COMMIT} -X main.AppVersion=${APP_VERSION}"

docker-build: version
	docker build --build-arg GIT_COMMIT=$(GIT_COMMIT) --build-arg GIT_STATE=$(GIT_STATE) --build-arg APP_VERSION=$(APP_VERSION) -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	
docker-push:
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
