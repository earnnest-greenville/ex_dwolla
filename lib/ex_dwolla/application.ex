defmodule ExDwolla.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {ExDwolla.AuthStore, %{
        environment: Application.get_env(:ex_dwolla, :environment, "dev"),
        key: Application.get_env(:ex_dwolla, :key),
        secret: Application.get_env(:ex_dwolla, :secret),
      }},
    ]

    opts = [strategy: :one_for_one, name: ExDwolla.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def http_client(), do: Application.get_env(:ex_dwolla, :http_client, :httpc)
end
