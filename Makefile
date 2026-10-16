.PHONY: build test vet preflight clean release

build:
	mkdir -p dist
	CGO_ENABLED=0 go build -trimpath -o dist/quirea ./cmd/quirea
	CGO_ENABLED=0 go build -trimpath -o dist/quirea-worker ./cmd/quirea-worker

test:
	go test ./...

vet:
	go vet ./...

preflight:
	./scripts/preflight.sh

release:
	./scripts/build-release.sh

clean:
	rm -rf dist
