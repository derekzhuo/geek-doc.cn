FROM ubuntu:24.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends netgen-lvs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
ENTRYPOINT ["./run.sh"]
