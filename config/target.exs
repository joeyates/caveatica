import Config

# This configuration is read when building the Nerves firmware

config :shoehorn, init: [:nerves_runtime, :nerves_pack]

config :nerves, :erlinit, update_clock: true

keys =
  [
    Path.join([System.user_home!(), ".ssh", "id_rsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ecdsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ed25519.pub"])
  ]
  |> Enum.filter(&File.exists?/1)

if keys == [] do
  Mix.raise("""
    No SSH public keys found in ~/.ssh. An ssh authorized key is needed to
    log into the Nerves device and update firmware on it using ssh.
    See your project's config.exs for this error message.
  """)
end

config :nerves_ssh, :authorized_keys, Enum.map(keys, &File.read!/1)

config :caveatica, :server_fqdn, System.fetch_env!("CAVEATICA_SERVER_FQDN")
config :caveatica, :server_user, System.fetch_env!("CAVEATICA_SERVER_USER")

wlan0_config =
  case {System.get_env("WIFI_SSID"), System.get_env("WIFI_PASSPHRASE")} do
    {nil, nil} ->
      %{type: VintageNetWiFi}

    {ssid, nil} ->
      %{
        type: VintageNetWiFi,
        vintage_net_wifi: %{
          networks: [
            %{
              key_mgmt: :none,
              ssid: ssid
            }
          ]
        },
        ipv4: %{method: :dhcp}
      }

    {ssid, passphrase} ->
      %{
        type: VintageNetWiFi,
        vintage_net_wifi: %{
          networks: [
            %{
              key_mgmt: :wpa_psk,
              ssid: ssid,
              psk: passphrase
            }
          ]
        },
        ipv4: %{method: :dhcp}
      }
  end

config :vintage_net,
  regulatory_domain: "IT", # TODO
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{method: :dhcp}
     }},
    {"wlan0", wlan0_config}
  ]

config :mdns_lite,
  host: [:hostname, "nerves"],
  ttl: 120,

  # Advertise the following services over mDNS.
  services: [
    %{
      name: "SSH Remote Login Protocol",
      protocol: "ssh",
      transport: "tcp",
      port: 22
    },
    %{
      name: "Secure File Transfer Protocol over SSH",
      protocol: "sftp-ssh",
      transport: "tcp",
      port: 22
    },
    %{
      name: "Erlang Port Mapper Daemon",
      protocol: "epmd",
      transport: "tcp",
      port: 4369
    }
  ]
