# to complete later
NAME := yaml
VERSION := $(cat VERSION)

SRCS      := $(shell find . -name '*.go' -type f)
LDFLAGS   := -ldflags "	-X github.com/sniperkit/snk.golang.$(NAME)/version.Version=$(VERSION)

GH_UPLOAD := github-release upload --user sniperkit --repo $(NAME) --tag $(VERSION)

.PHONY: version
version:
	go run $(LDFLAGS) *.go -v

.PHONY: erd
erd:
	@mkdir -p ./shared/build
	@go-erd -path ./pkg/widget |dot -Tsvg > ./shared/build/widget_erd.svg
	@go-erd -path ./pkg/model |dot -Tsvg > ./shared/build/model_erd.svg
	@go-erd -path ./model/vector |dot -Tsvg > ./shared/build/vector_erd.svg

.PHONY: fmt
fmt:
	gofmt -s -w ./pkg/... ./plugin/...

.PHONY: clean
clean:
	rm -rf ./dist/ ./bin/

.PHONY: build
build: deps clean ## local build
	@go build $(LDFLAGS) -o ./bin/$(NAME) ./cmd/$(NAME)

.PHONY: install ## local install to GOBIN
install: deps clean
	@go install $(LDFLAGS) github.com/sniperkit/snk.golang.mcc/cmd/$(NAME)

.PHONY: dist
dist: deps clean ## dist builds before release
	@mkdir -p ./dist
	@rm -fR ./dist/*
	CGO_ENABLED="1" gox $(LDFLAGS) -osarch="windows/amd64 windows/386 linux/amd64 darwin/amd64 linux/386 darwin/386" -output="dist/{{.Name}}_${VERSION}_{{.OS}}_{{.Arch}}/{{.Dir}}" ./cmd/...

deps: ## ensure dependencies
	@glide install --strip-vendor

# test > textfile > cat > rm... this is necessary because screen would be flush during tests
.PHONY: test
test:
	@mkdir -p ./bin/debug
	@rm -f ./bin/debug/test.output
	@go test ./pkg/... ./plugins/... -cover > ./bin/debug/test.output && cat ./bin/debug/test.output

# same reason above
.PHONY: bench
bench:
	@mkdir -p ./bin/debug
	@rm ./bin/debug/bench.txt
	@go test ./pkg/... ./plugins/... -bench . -benchmem > ./bin/debug/bench.txt && cat ./bin/debug/bench.txt


.PHONY: lines
lines:
	@echo "=== implements =========================="
	@wc -l $(shell find . -name "*.go" | grep -v /vendor/ | grep -v _test.go)
	@echo "--- without line break & comment line"
	@find . -name "*.go" | grep -v /vendor/ | grep -v _test.go | xargs grep -h "^\s*[^\/\/]" | wc -l
	@echo "=== test code ==========================="
	@wc -l $(shell find . -name "*_test.go" | grep -v /vendor/)
	@echo "--- without line break & comment line"
	@find . -name "*_test.go" | grep -v /vendor/ | xargs grep -h "^\s*[^\/\/]" | wc -l

.PHONY: release
release:
	@make clean
	@make build
	mkdir release
	go get github.com/aktau/github-release/...
	cp -R _build/* release
	github-release release \
		--user qmu \
		--repo $(NAME) \
		--tag $(VERSION) \
		--name $(VERSION)

	cd release/ \
		&& $(GH_UPLOAD) --name darwin_386_$(NAME) --file ${NAME}_${VERSION}_darwin_386/$(NAME) \
		&& $(GH_UPLOAD) --name darwin_amd64_$(NAME) --file ${NAME}_${VERSION}_darwin_amd64/$(NAME) \
		&& $(GH_UPLOAD) --name linux_386_$(NAME) --file ${NAME}_${VERSION}_linux_386/$(NAME) \
		&& $(GH_UPLOAD) --name linux_amd64_$(NAME) --file ${NAME}_${VERSION}_linux_amd64/$(NAME) \
		&& tar czvf ${NAME}_${VERSION}_darwin_amd64.tar.gz ${NAME}_${VERSION}_darwin_amd64/ \
		&& $(GH_UPLOAD) --name ${NAME}_${VERSION}_darwin_amd64.tar.gz --file ${NAME}_${VERSION}_darwin_amd64.tar.gz \
		&& echo openssl dgst -sha256 ${NAME}_${VERSION}_darwin_amd64.tar.gz

	git fetch --tags
