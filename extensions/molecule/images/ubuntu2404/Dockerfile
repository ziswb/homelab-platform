# Molecule test image for the k3s node roles: Ubuntu 24.04 with systemd as PID 1.
FROM docker.io/library/ubuntu:25.10@sha256:7cc5e35f6567ee8c66d2abb4aab0fd866669e6207c237c3a8f0947a5c7f17092

ENV container=docker \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates iproute2 python3 python3-apt sudo systemd systemd-sysv \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
