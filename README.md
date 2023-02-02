# Caveatica

Control a door to a chicken coop.

This is a Nerves application.

# Setup

## Install A Compatible Erlang Version

Get version of nerves_system_rpi3 from mix.lock
Check https://hexdocs.pm/nerves/systems.html#compatibility under rpi3

## Other

```sh
sudo apt install libmnl-dev
mix archive.install hex nerves_bootstrap
mix deps.get
```

# Build

```sh
export MIX_TARGET=rpi3
export WIFI_SSID=...
export WIFI_PASSPHRASE=...
mix firmware
mix firmware.burn
```
