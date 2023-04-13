import Config

# Configuration when running on the host.

config :logger, :default_formatter,
  format: "$date $time $metadata[$level] $message\n"
