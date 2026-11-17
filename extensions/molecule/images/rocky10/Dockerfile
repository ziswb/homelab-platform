# Molecule test image for the central host roles: Rocky Linux 10 with systemd as PID 1.
FROM docker.io/rockylinux/rockylinux:10@sha256:d24beedc58f79b9e0e9289fedaa4fcbcbe692b1438883a86f177fd7c51053ca8

ENV container=docker

RUN dnf -y install iproute python3 sudo systemd \
 && dnf clean all

STOPSIGNAL SIGRTMIN+3
CMD ["/usr/sbin/init"]
