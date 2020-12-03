# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :logger,
  backends: [:console],
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ],
  level: :warn

config :kvs,
  server: KVS,
  partitions: 8,
  nodes: 8,
  workers: 3,
  readers: 2,
  writers: 2,
  timeout: 200

#config :ring,
#  partitions: 8,
#  nodes: 8

