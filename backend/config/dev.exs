import Config

# Configure your database
config :ezstanza, Ezstanza.Repo,
  username: "ezstanza_dev",
  password: "ezstanza_dev",
  hostname: "localhost",
  database: "ezstanza_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :ezstanza, EzstanzaWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "6MTiIiGt4j0yqZ3Zurr0B0BZo9w64TW88DySW7/43+4Nu+1W9FueXqi3oqbLpNCA",
  watchers: []

config :ezstanza, Ezstanza.DeploymentProvider.SSH,
  #key_file: "/home/david/.ssh/id_rsa.pem", #System.get_env("EZSTANZA_DEPLOY_SSH_KEY_FILE"),
  #known_hosts_file: "/home/david/.ssh/known_hosts", #System.get_env("EZSTANZA_DEPLOY_KNOWN_HOSTS_FILE"),
  ssh_user_dir: "/home/david/.ssh/ezstanza",
  ezproxy_stanzas_config_file: "/data/ezproxy/config-files/databases.txt", #path/file??
  ezproxy_stanzas_configs_archive_dir: "/data/ezproxy/configs-archive", #path/file??
  ezproxy_restart_command: "/usr/local/bin/restart-ezproxy-test.sh"

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
