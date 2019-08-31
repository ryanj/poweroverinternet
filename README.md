# Power Over Internet

a poorly-named container that monitors net availability, attempting to restart your connection via GPIO signaling when the network becomes unresponsive

Inspired by:

 * https://fedoramagazine.org/turnon-led-fedora-iot/

Requirements:

 * an Internet connection that requires an occaisional reboot
 * a Raspberry Pi or similar (ARM64 with GPIO)
 * http://iotrelay.com
 * two wires

WARNING!: this container attempts to drop your internet connection via GPIO

Usage info:

```bash
sudo podman run -d -it --name rerouter --device=/dev/gpiochip0 ryanj/poweroverinternet:v1
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
