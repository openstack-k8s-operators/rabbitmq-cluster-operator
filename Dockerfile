
# Build the manager binary
FROM --platform=$BUILDPLATFORM registry.access.redhat.com/ubi9/go-toolset:1.21 as builder

WORKDIR /workspace

USER root

# Dependencies are cached unless we change go.mod or go.sum
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/
COPY internal/ internal/
COPY pkg/ pkg/

# Build
ARG TARGETOS
ARG TARGETARCH
ENV GOOS $TARGETOS
ENV GOARCH $TARGETARCH
RUN CGO_ENABLED=1 GO111MODULE=on go build -a -tags 'strictfipsruntime timetzdata' -o manager main.go

# ---
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ARG GIT_COMMIT
LABEL GitCommit=$GIT_COMMIT

WORKDIR /
COPY --from=builder /workspace/manager .
RUN echo "rabbitmq-cluster-operator:x:1000:" > /etc/group && \
    echo "rabbitmq-cluster-operator:x:1000:1000::/home/rabbitmq-cluster-operator:/usr/sbin/nologin" > /etc/passwd

USER 1000:1000

ENTRYPOINT ["/manager"]
