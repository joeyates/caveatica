# Hardware

A motor raises or lowers a portcullis-style door.
The motor is controlled by a Raspberry Pi via two relays.
One relay creates a positive DC voltage across the motor
driving it one way, the other does the opposite.

# Applications

There are two applications

* A Nerves application,
* A remote control host.

## Nerves Application

Nerves runs on a Raspberry Pi inside the chicken coop.
It sets up networking with the control host and electrically controls the motor.

# Control Host

The control host exposes a Web UI to signal the Nerves application
to open or close the door.

# Networking

Caveatica.Epmd runs `epmd` and sets up external access.

The instance of `epmd` on the Raspberry Pi is used by
both the Nerves application and the control host.

Caveatica.Epmd sets up two SSH reverse tunnels
from the Raspberry Pi, which is assumed to be behind a firewall,
out to the control host.

One tunnel is to give the control host access to `epmd` on port 4369,
the other is to give it access to the Nerves instance on port 5555.

When the Nerves application starts, it forces port 5555 to be the only
port that it will listen on for distributed calls (see rel/vm.args.eex).

Both the Nerves application and the control host register themselves
with `epmd` as distributed nodes.
