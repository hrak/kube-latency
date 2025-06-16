ARG GIT_STATE=""
ARG GIT_COMMIT=""
ARG APP_VERSION=""

FROM golang:1.24-alpine AS build

ARG GIT_STATE
ARG GIT_COMMIT
ARG APP_VERSION

WORKDIR /app
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
COPY vendor/ vendor/

# Copy the go source
COPY main.go main.go
COPY app.go app.go

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -o kube-latency -ldflags "-X main.AppGitState=${GIT_STATE} -X main.AppGitCommit=${GIT_COMMIT} -X main.AppVersion=${APP_VERSION}"

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/static:latest AS final

ARG GIT_COMMIT

COPY --from=build /app/kube-latency /kube-latency
CMD ["/kube-latency"]
LABEL org.label-schema.vcs-ref=$GIT_COMMIT \
      org.label-schema.vcs-url="https://github.com/hrak/kube-latency" \
      org.label-schema.license="Apache-2.0"
