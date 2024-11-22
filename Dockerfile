FROM alpine:3 AS downloader

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG VERSION

ENV BUILDX_ARCH="${TARGETOS:-linux}_${TARGETARCH:-amd64}${TARGETVARIANT}"

RUN wget https://github.com/pocketbase/pocketbase/releases/download/v${VERSION}/pocketbase_${VERSION}_${BUILDX_ARCH}.zip \
    && unzip pocketbase_${VERSION}_${BUILDX_ARCH}.zip \
    && chmod +x /pocketbase

FROM alpine:3

RUN apk update && \
    apk add --no-cache ca-certificates && \
    rm -rf /var/cache/apk/*

COPY --from=downloader /pocketbase /usr/local/bin/pocketbase

# Create directories with appropriate permissions
RUN mkdir -p /pb_data /pb_public /pb_hooks && \
    chown -R nobody:nobody /pb_data /pb_public /pb_hooks

EXPOSE 8090

# Switch to non-root user
USER nobody

# Update ENTRYPOINT to use shell form to allow environment variable expansion
ENTRYPOINT pocketbase serve \
    --http=0.0.0.0:8090 \
    --dir=/pb_data \
    --publicDir=/pb_public \
    --hooksDir=/pb_hooks \
    --encryptionEnv=ENCRYPTION
    --debug
