# ⚡POWER🔃OVER📶INTERNET🔌

a poorly-named service that uses GPIO signaling to restore failed network connections

Inspired by:

 * https://fedoramagazine.org/turnon-led-fedora-iot/

Requirements:

 * an unreliable Internet connection
 * a Raspberry Pi or similar (ARM64 with GPIO)
 * an AC/DC Control Relay, available from http://iotrelay.com
 * two spare wires

## Disclaimers

1. **WARNING: this container attempts to drop your internet connection via GPIO!**
2. *USE AT YOUR OWN RISK!!! (see LICENCE for additional detils)*
3. for additional support - call your internet service provider (or consider finding a new one)!

## Basics
Basic usage with `docker` or `podman`:

```bash
sudo podman run -it --name rerouter -e DEBUG_OUT=enabled --device=/dev/gpiochip0 ryanj/poweroverinternet:v1
```

Example output:

```
⚡POWER🔃OVER📶INTERNET🔌
1. 📶🤔 Check google.com:443 for availability...
2. ⚡🔌 Send net restart trigger events via gpiochip0 pin 21
📶📡 checking uplink...
📶🖖 net uplink active
🤖💤 sleeping for 60s...
📶📡 checking uplink...
⚠️ ↪️  lookup failed - trying again...
📶❌ network uplink is unavailable!
⚡🔃 restarting network uplink...
🔌💫 net restart trigger issued via gpiochip0 pin 21
📶✨ waiting 60s for network uplink to restart...
⏳⏳ waiting...
⏳ waiting...
⌛ waiting...
📶📡 testing uplink...
🤔 testing uplink...
🤔 testing uplink...
🤔 testing uplink...
📶✅ network uplink restored!
📶🌟 net connection recovered after 77 seconds of downtime
📶📡 checking uplink...
📶🖖 net uplink active
🤖💤 sleeping for 60s...
```

### Configuration

By default, this service will attempt to contact `google.com` on port `443`.  Env keys can be used to configure the service with `REMOTE_SERVER` and `REMOTE_PORT` settings:

```bash
sudo podman run -d -it --rm --name rerouter -e REMOTE_SERVER=192.168.1.1 -e REMOTE_PORT=80 --device=/dev/gpiochip0 ryanj/poweroverinternet:v1
```

These settings assume that you have a router or cable modem configured to respond on `192.168.1.1:80`.

In the event that the service is unable to make a connection to the configured host and port address, a trigger signal will be sent to the configured GPIO headers, which (when configured correctly) will activate the AC/DC control relay to restart any connected hardware devices.

### Installation

This service can be installed and managed via Kubernetes or systemd.

Example systemd unit: [poweroverinternet.service](https://raw.githubusercontent.com/ryanj/poweroverinternet/master/poweroverinternet.service)

To install this systemd unit on Fedora30 IoT, try:

```bash
sudo curl -o /etc/systemd/system/poweroverinternet.service https://raw.githubusercontent.com/ryanj/poweroverinternet/master/poweroverinternet.service
```

Fix permissions, and review the new service configuration:
```bash
sudo chmod 664 /etc/systemd/system/poweroverinternet.service
cat /etc/systemd/system/poweroverinternet.service
```

Update the environment keys as needed. See [#configuration](#Configuration) for details.

When ready, load the systemd unit and mark it active:
```bash
sudo systemctl daemon-reload
sudo systemctl enable poweroverinternet
```

Check the status of the service with:
```bash
sudo systemctl status poweroverinternet
```

### Development

Tested and developed on Fedora 30 IoT

local:

```bash
sudo IDLE_SECONDS=2 DEBUG_OUT=enabled REMOTE_SERVER=192.168.1.1 REMOTE_PORT=80 ./poweroverinternet.sh
```

build:

```bash
sudo podman build --tag fedora:poweroverinternet -f ./Dockerfile
```

test:

```bash
sudo podman run -it --name rerouter_test --device=/dev/gpiochip0 localhost/fedora:poweroverinternet
```

share:

```bash
sudo podman tag
sudo podman push
```
