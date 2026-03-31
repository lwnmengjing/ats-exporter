.PHONY: build clean test docker run

BINARY_NAME=ats-exporter
VERSION?=unknown
REVISION?=unknown
BRANCH?=unknown
BUILD_DATE=$(shell date -u +%Y-%m-%dT%H:%M:%SZ)
GO_VERSION=$(shell go version | awk '{print $$3}')

LDFLAGS=-ldflags "-X main.Version=${VERSION} \
	-X main.Revision=${REVISION} \
	-X main.Branch=${BRANCH} \
	-X main.BuildDate=${BUILD_DATE} \
	-X main.GoVersion=${GO_VERSION}"

build:
	go build ${LDFLAGS} -o ${BINARY_NAME} .

clean:
	go clean
	rm -f ${BINARY_NAME}

test:
	go test -v ./...

docker:
	docker build -t ats-exporter:${VERSION} .

run:
	./${BINARY_NAME} --log.level=debug

lint:
	golangci-lint run

fmt:
	go fmt ./...

vet:
	go vet ./...

mod:
	go mod tidy
	go mod download