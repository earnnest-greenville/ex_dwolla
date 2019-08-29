use Mix.Config

config :ex_dwolla,
  environment: "dev",
  key: System.get_env("DWOLLA_KEY"),
  secret: System.get_env("DWOLLA_SECRET")