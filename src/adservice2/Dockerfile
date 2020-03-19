FROM golang:1.14-alpine as builder
RUN apk add --no-cache ca-certificates git && \
      wget -qO/go/bin/dep https://github.com/golang/dep/releases/download/v0.5.0/dep-linux-amd64 && \
      chmod +x /go/bin/dep

ENV PROJECT github.com/tetratelabs/microservices-demo/src/adservice2
ARG ADSERVICE_VERSION="0.1.6-dev"

WORKDIR /go/src/$PROJECT

COPY . .
RUN go install -v -ldflags "-X main.version=${ADSERVICE_VERSION}" .

FROM alpine as release
RUN apk add --no-cache ca-certificates \
    busybox-extras net-tools bind-tools
WORKDIR /adservice
COPY --from=builder /go/bin/adservice2 /adservice/server
COPY ./ads.json ./ads.json
EXPOSE 9555
ENTRYPOINT ["/adservice/server"]
