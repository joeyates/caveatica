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




