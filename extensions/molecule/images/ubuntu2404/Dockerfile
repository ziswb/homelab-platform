# Molecule test image for the k3s node roles: Ubuntu 24.04 with systemd as PID 1.
FROM docker.io/library/ubuntu:24.04@sha256:9c7f200c07e3d4a03e7249d2c16bf66a51120fb876aa2242cf31451412543289

ENV container=docker \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates iproute2 python3 python3-apt sudo systemd systemd-sysv \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
