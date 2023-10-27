defmodule Ezstanza.DeploymentProvider.SSH do
  use Ezstanza.DeploymentProvider

  require Logger

  @otp_app :ezstanza

  form_schema do
    form_field :hostname, :string,
      label: "Hostname",
      help_text: "SSH hostname",
      component: :text,
      required: true
    form_field :port, :integer,
      label: "Port",
      help_text: "SSH port",
      component: :number,
      required: true
    form_field :user, :string,
      label: "User",
      help_text: "SSH user",
      component: :text,
      required: true
    form_field :path, :string,
      label: "Path",
      help_text: "Remote deployment path",
      component: :text,
      required: true
  end

  @impl Ezstanza.DeploymentProvider
  def changeset_alter(changeset) do
    changeset
  end

  @impl Ezstanza.DeploymentProvider
  def deploy(target_name, user, stanzas_config, options) do
    #TODO: tmp_dir option
    #TODO: unique constraint for name in schema
    tmp_local_config_file = "/tmp/#{target_name}_config.txt"
    case File.write(tmp_local_config_file, stanzas_config) do
      :ok ->
        restart_command = config(:ezproxy_restart_command)
        remote_config_file = config(:ezproxy_stanzas_config_file)

        #TODO: Copy old config if archive dir set
        archive_dir = config(:ezproxy_stanzas_configs_archive_dir)
        context = sshkit_context(options.user, options.hostname, options.port)
        cleanup = fn -> File.rm!(tmp_local_config_file) end

        with [:ok] <- SSHKit.upload(context, tmp_local_config_file, as: remote_config_file),
             [{:ok, _, 0}] <- SSHKit.run(context, restart_command)
        do
          cleanup.()
          :ok
        else
          [{:error, reason}] ->
            IO.puts("SSKIT ERROR #{reason}")
            cleanup.()
            #TODO: Logger
            {:error, :failed}
        end
      {:error, reason} ->
        Logger.error("Could not write to #{tmp_local_config_file}, reason: #{reason}")
        {:error, :failed}
    end
  end

  defp config(key) do
    Application.get_env(@otp_app, __MODULE__)
    |> Keyword.get(key)
  end

  defp config() do
    Application.get_env(@otp_app, __MODULE__)
  end

  defp sshkit_context(user, hostname, port) do
    hosts = [{hostname, port: port, silently_accept_hosts: true}]
    # TODO: Only use key_cb if relevant options are defined
    # otherwise fallback on defaults
    #
#    sshkit_options = Enum.reduce(config(), [], fn
#      {:known_hosts_file, known_hosts_file}, acc ->
#        [{:known_hosts, File.open!(known_hosts_file, [:read, :write])} | acc]
#      {:key_file, key_file}, acc ->
#        [{:identity, File.open!(key_file, [:read])} | acc]
#      _, acc ->
#        acc
#    end)
#    |> case do
#      [] ->
#        []
#      options ->
#        [key_cb: key_cb(options)]
#    end
    sshkit_options = Enum.reduce(config(), [], fn
      {:ssh_user_dir, user_dir}, acc ->
        [{:user_dir, user_dir} | acc]
      _, acc ->
        acc
    end)
    |> Keyword.merge([
      user: user
    ])
    SSHKit.context(hosts, sshkit_options)
    |> SSHKit.user(user) # Seems to be remote user???
  end

  defp key_cb(options) do
    SSHClientKeyAPI.with_options([{:silently_accept_hosts, true} | options])
  end
end
