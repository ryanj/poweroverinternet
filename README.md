# Power Over Internet

a poorly-named container that monitors net accessibility, and reboots your router when unresponsive

WARNING!: don't use this - it's designed to drop your internet connection via GPIO

Pre-requisites:
 * https://fedoramagazine.org/turnon-led-fedora-iot/
 * http://iotrelay.com

Usage info:

```bash
podman run -d -it --name rerouter --device=/dev/gpiochip0 ryanj:poweroverinternet
```

### Development

build:

```bash
sudo podman build --tag fedora:poweroverinternet -f ./Dockerfile
```

test:

```bash
sudo podman run -it --name rerouter_test --device=/dev/gpiochip0 localhost/fedora:poweroverinternet
```
