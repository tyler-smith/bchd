APPNAME ?= bchd
CLINAME = bchctl
OUTDIR = pkg

# Allow user to override cross compilation scope
OSARCH ?= darwin/386 darwin/amd64 dragonfly/amd64 freebsd/386 freebsd/amd64 freebsd/arm linux/386 linux/amd64 linux/arm netbsd/386 netbsd/amd64 netbsd/arm openbsd/386 openbsd/amd64 plan9/386 plan9/amd64 solaris/amd64 windows/386 windows/amd64
DIRS ?= darwin_386 darwin_amd64 dragonfly_amd64 freebsd_386 freebsd_amd64 freebsd_arm linux_386 linux_amd64 linux_arm netbsd_386 netbsd_amd64 netbsd_arm openbsd_386 openbsd_amd64 plan9_386 plan9_amd64 solaris_amd64 windows_386 windows_amd64

all:
	go build .
	go build ./cmd/bchctl

compile:
	gox -osarch="$(OSARCH)" -output "$(OUTDIR)/$(APPNAME)-{{.OS}}_{{.Arch}}/$(APPNAME)"
	gox -osarch="$(OSARCH)" -output "$(OUTDIR)/$(APPNAME)-{{.OS}}_{{.Arch}}/$(CLINAME)" ./cmd/bchctl
	@for dir in $(DIRS) ; do \
		(cp README.md $(OUTDIR)/$(APPNAME)-$$dir/README.md) ;\
		(cp LICENSE $(OUTDIR)/$(APPNAME)-$$dir/LICENSE) ;\
		(cp sample-bchd.conf $(OUTDIR)/$(APPNAME)-$$dir/sample-bchd.conf) ;\
		(cd $(OUTDIR) && zip -q $(APPNAME)-$$dir.zip -r $(APPNAME)-$$dir) ;\
		echo "make $(OUTDIR)/$(APPNAME)-$$dir.zip" ;\
	done

install:
	go install .
	go install ./cmd/bchctl

uninstall:
	go clean -i
	go clean -i ./cmd/bchctl

docker:
	docker build -t $(APPNAME) .


protoc-go:
	protoc -I=bchrpc/ bchrpc/bchrpc.proto --go_out=plugins=grpc:bchrpc/pb

protoc-py:
	# python -m pip install grpcio-tools
	python -m grpc_tools.protoc -I=bchrpc/ --python_out=bchrpc/pb-py --grpc_python_out=bchrpc/pb-py bchrpc/bchrpc.proto

protoc-js:
	protoc -I=bchrpc/ \
		--plugin=protoc-gen-ts=$(HOME)/node_modules/.bin/protoc-gen-ts \
		--js_out=import_style=commonjs,binary:bchrpc/pb-js \
		--ts_out=service=true:bchrpc/pb-js \
		bchrpc/bchrpc.proto

protoc-all:
	protoc -I=bchrpc/ bchrpc/bchrpc.proto --go_out=plugins=grpc:bchrpc/pb
	python -m grpc_tools.protoc -I=bchrpc/ --python_out=bchrpc/pb-py --grpc_python_out=bchrpc/pb-py bchrpc/bchrpc.proto
	protoc -I=bchrpc/\
		--plugin=protoc-gen-ts=$(HOME)/node_modules/.bin/protoc-gen-ts \
		--js_out=import_style=commonjs,binary:bchrpc/pb-js \
		--ts_out=service=true:bchrpc/pb-js \
		bchrpc/bchrpc.proto

SNOWGLOBE_PROFILE ?= tylersmith
SNOWGLOBE_VERSION ?= $(shell git describe --tags --abbrev=0)
SNOWGLOBE_IMAGE_NAME ?= $(SNOWGLOBE_PROFILE)/snowglobe:$(SNOWGLOBE_VERSION)

snowglobe:
	docker build -t $(SNOWGLOBE_IMAGE_NAME) .

push_snowglobe:
	docker push $(SNOWGLOBE_IMAGE_NAME)