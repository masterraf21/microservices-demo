FROM golang:1.13-alpine as builder
RUN apk add --no-cache ca-certificates git && \
    wget -qO/go/bin/dep https://github.com/golang/dep/releases/download/v0.5.0/dep-linux-amd64 && \
    chmod +x /go/bin/dep

ENV PROJECT github.com/GoogleCloudPlatform/microservices-demo/src/apiservice
WORKDIR /go/src/$PROJECT

COPY . .
RUN go install .

FROM alpine as release
RUN apk add --no-cache ca-certificates \
    busybox-extras net-tools bind-tools
WORKDIR /apiservice
COPY --from=builder /go/bin/apiservice /apiservice/server
EXPOSE 8080
ENTRYPOINT ["/apiservice/server"]
