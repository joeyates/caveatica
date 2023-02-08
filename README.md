# Caveatica

Open and shut the door to a chicken coop.

This is a Nerves application that runs on a Raspberry Pi
housed inside the chicken coop.

The Raspberry Pi controls a motor that raises or lowers
a "portcullis" style door.

The application is controlled by a remote "Caveatica server"
application.

# Setup

## Install A Compatible Erlang Version

Get version of nerves_system_rpi3 from mix.lock
Check https://hexdocs.pm/nerves/systems.html#compatibility under rpi3

With asdf:

```
asdf install
```

## Create .envrc.private

This project relies on direnv to set environment variables on
the development machine.

The file `.envrc` lists variables that need to be set.

```
cp .envrc .envrc.private
```

Then insert the values that match your setup.

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

# Prepare SD Card

```sh
bin/burn
```

# Switching Target

* change .envrc.private
* change `@target` in mix.exs
* run mix deps.get

# Development

## Updating nerves Runtime

The OTP version of the nerves runtime (check the GitHub release page)
must match the Erlang that is used when building the firmware.
