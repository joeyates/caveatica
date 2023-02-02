import Config

Application.start(:nerves_bootstrap)

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

config :logger, backends: [RingLogger]

if Mix.target() == :host do
  import_config "host.exs"
else
  import_config "target.exs"
end
