# Start from a Debian image with the latest version of Go installed
# and a workspace (GOPATH) configured at /go.
# FROM golang
FROM golang:1.13-alpine3.10

LABEL maintainer="Josh Ellithorpe <quest@mac.com>"

# Copy the local package files to the container's workspace.
ADD . /go/src/github.com/gcash/bchd

# Switch to the correct working directory.
WORKDIR /go/src/github.com/gcash/bchd

# Install upx
# RUN apt-get update && apt-get install -y xz-utils && \
#   curl -L -o /usr/local/upx-3.95-amd64_linux.tar.xz https://github.com/upx/upx/releases/download/v3.95/upx-3.95-amd64_linux.tar.xz && \
#   xz -d -c /usr/local/upx-3.95-amd64_linux.tar.xz | \
#   tar -xOf - upx-3.95-amd64_linux/upx > /bin/upx && \
#   chmod a+x /bin/upx


# Build the code and the cli client.
RUN go install .
RUN go install ./cmd/bchctl
# RUN /bin/upx --ultra-brute -qq /go/bin/bchd && /bin/upx -t /go/bin/bchd
# RUN /bin/upx --ultra-brute -qq /go/bin/bchctl && /bin/upx -t /go/bin/bchctl



# RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build --ldflags '-s -w -extldflags "-static"' -o /opt/bchd . && /bin/upx --ultra-brute -qq /opt/bchd && /bin/upx -t /opt/bchd
# RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build --ldflags '-s -w -extldflags "-static"' -o /opt/bchcli ./cmd/bchctl && /bin/upx --ultra-brute -qq /opt/bchctl && /bin/upx -t /opt/bchctl

# # Symlink the config to /root/.bchd/bchd.conf
# # so bchctl requires fewer flags.
# RUN mkdir -p /root/.bchd
# RUN ln -s /data/bchd.conf /root/.bchd/bchd.conf

# # Create the data volume.
# VOLUME ["/data"]

# # Set the start command. This starts bchd with
# # flags to save the blockchain data and the
# # config on a docker volume.
# ENTRYPOINT ["bchd", "--addrindex", "--txindex", "-b", "/data", "-C", "/data/bchd.conf"]

# # Document that the service listens on port 8333.
# EXPOSE 8333



# Create final image
# FROM openbazaar/base:v1.0.0
# FROM alpine:3.10.2
# COPY --from=0 /opt/bchd /opt/bchd
# COPY --from=0 /opt/bchctl /opt/bchctl
# COPY --from=0 /go/bin/bchd /go/bin/bchd
# COPY --from=0 /go/bin/bchctl /go/bin/bchctl

# Symlink the config to /root/.bchd/bchd.conf
# so bchctl requires fewer flags.
RUN mkdir -p /root/.bchd
RUN ln -s /data/bchd.conf /root/.bchd/bchd.conf

# Create the data volume.
VOLUME ["/data"]

# Set the start command. This starts bchd with
# flags to save the blockchain data and the
# config on a docker volume.
ENTRYPOINT ["bchd", "--addrindex", "--txindex", "-b", "/data", "-C", "/data/bchd.conf"]

# Document that the service listens on port 8333.
EXPOSE 8333