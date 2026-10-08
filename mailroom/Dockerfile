# Mailroom is the flow engine RapidPro calls into. It runs from the same v9.0.0 release that the upstream CI downloads.
# Built from this repo's root context, so it's deployed as a separate Railway service pointed at this path.
FROM debian:bookworm-slim
ARG MAILROOM_VERSION=9.0.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL "https://github.com/nyaruka/mailroom/releases/download/v${MAILROOM_VERSION}/mailroom_${MAILROOM_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin mailroom

# configured through MAILROOM_* variables on the Railway service; these defaults make it listen on the private network
ENV MAILROOM_ADDRESS=0.0.0.0 \
    MAILROOM_PORT=8090
EXPOSE 8090

CMD ["mailroom"]
