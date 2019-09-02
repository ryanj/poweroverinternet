MAINTAINER ryanj <ryanj@redhat.com>
FROM fedora:latest
RUN  dnf -y update
RUN  dnf -y install nmap-ncat libgpiod-utils python3-libgpiod && dnf clean all
COPY poweroverinternet.sh ./
ENV REMOTE_SERVER=google.com \
    REMOTE_PORT=443 \
    GPIO_CHIP=gpiochip0 \
    GPIO_DOUT_PIN=21
ENTRYPOINT ["./poweroverinternet.sh"]
