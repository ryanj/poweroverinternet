MAINTAINER ryanj <ryanj@redhat.com>
FROM fedora:latest
RUN  dnf -y update
RUN  dnf -y install nmap-ncat libgpiod-utils python3-libgpiod && dnf clean all
COPY poweroverinternet.sh ./
ENTRYPOINT ["./poweroverinternet.sh"]
