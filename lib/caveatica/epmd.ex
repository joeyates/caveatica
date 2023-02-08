defmodule Caveatica.Epmd do
  @server_user Application.compile_env!(:caveatica, :server_user)
  @server_fqdn Application.compile_env!(:caveatica, :server_fqdn)
  @ssh_port 22
  @epmd_port 4369
  @caveatica_port 5555

  def start do
    :os.cmd('epmd -daemon')
    Node.start(:"caveatica@127.0.0.1")

    :ok = :ssh.start()
    {:ok, conn} = :ssh.connect(String.to_charlist(@server_fqdn), @ssh_port, ssh_config())
    :ssh.tcpip_tunnel_from_server(conn, '127.0.0.1', @epmd_port, '127.0.0.1', @epmd_port)
    :ssh.tcpip_tunnel_from_server(conn, '127.0.0.1', @caveatica_port, '127.0.0.1', @caveatica_port)
  end

  defp ssh_config do
    ssh_key_path = Application.app_dir(:caveatica, "priv")

    [
      user_interaction: false,
      silently_accept_hosts: true,
      user: String.to_charlist(@server_user),
      user_dir: String.to_charlist(ssh_key_path)
    ]
  end
end
