PROJECT?=github.com/johnhowlett/dt
APP?=dtservice
PORT?=8000

RELEASE?=0.0.4
COMMIT?=$(shell git rev-parse --short HEAD)
BUILD_TIME?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
CONTAINER_IMAGE?=docker.io/johnhowlett/${APP}

GOOS?=darwin
GOARCH?=amd64

# deletes the binary
clean:
	rm -f ${APP}

# maks a clean and new build of the git repo version
build: clean
	CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build \
		-ldflags "-s -w -X ${PROJECT}/version.Release=${RELEASE} \
		-X ${PROJECT}/version.Commit=${COMMIT} -X ${PROJECT}/version.BuildTime=${BUILD_TIME}" \
		-o ${APP}

# builds a docker container
container: 
	docker build -t $(CONTAINER_IMAGE):$(RELEASE) .

# run: container
# 	docker stop $(APP):$(RELEASE) || true && docker rm $(APP):$(RELEASE) || true
# 	docker run --name ${APP} -p ${PORT}:${PORT} --rm \
# 		-e "PORT=${PORT}" \
# 		$(APP):$(RELEASE)

run: build
	PORT=${PORT} ./${APP}

test:
	go test -v -race ./...

push: container
	docker push $(CONTAINER_IMAGE):$(RELEASE)

minikube: push
	for t in $(shell find ./kubernetes/docker -type f -name "*.yaml"); do \
        cat $$t | \
        	gsed -E "s/\{\{(\s*)\.Release(\s*)\}\}/$(RELEASE)/g" | \
        	gsed -E "s/\{\{(\s*)\.ServiceName(\s*)\}\}/$(APP)/g"; \
        echo ---; \
    done > tmp.yaml
	kubectl apply -f tmp.yaml
