# Caveatica

Control a door to a chicken coop.

This is a Nerves application.

# Setup

## Install A Compatible Erlang Version

Get version of nerves_system_rpi3 from mix.lock
Check https://hexdocs.pm/nerves/systems.html#compatibility under rpi3

With asdf:

```
asdf install
```

## Other

```sh
sudo apt install libmnl-dev
mix archive.install hex nerves_bootstrap
mix deps.get
```

## SSH Access

```sh
ssh-keygen -t ed25519 -b 4096 -N "" -C "Caveatica tunnel" -f "priv/id_ed25519"
```

Copy the public key to the Caveatica public server.

# Build

```sh
export MIX_TARGET=rpi3
export WIFI_SSID=...
export WIFI_PASSPHRASE=...
mix firmware
mix firmware.burn
```

# Switching Target

* change .envrc
* change `@target` in mix.exs
* run mix deps.get

# Development

## Updating nerves Runtime

The OTP version of the nerves runtime (check the GitHub release page)
must match the Erlang that is used when building the firmware.
