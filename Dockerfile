ARG BIN_NAME=energybridge_to_influxdb
ARG BIN_VERSION=<unknown>

FROM golang:1-alpine AS builder
ARG BIN_NAME
ARG BIN_VERSION
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-X main.version=${BIN_VERSION}" -o ./out/${BIN_NAME} .

FROM alpine:3
ARG BIN_NAME
RUN apk update && apk add --no-cache bash ca-certificates
COPY --from=builder /src/out/${BIN_NAME} /usr/bin/${BIN_NAME}
COPY docker.sh /docker.sh
CMD /docker.sh

LABEL license="MIT"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="Chris Dzombak <https://www.dzombak.com>"
LABEL org.opencontainers.image.authors="Chris Dzombak <https://www.dzombak.com>"
LABEL org.opencontainers.image.url="https://github.com/cdzombak/energybridge_to_influxdb"
LABEL org.opencontainers.image.documentation="https://github.com/cdzombak/energybridge_to_influxdb/blob/main/README.md"
LABEL org.opencontainers.image.source="https://github.com/cdzombak/energybridge_to_influxdb.git"
LABEL org.opencontainers.image.version="${BIN_VERSION}"
LABEL org.opencontainers.image.title="${BIN_NAME}"
LABEL org.opencontainers.image.description="Pull electricity usage readings from an Energy Bridge via MQTT and ship them to InfluxDB"
