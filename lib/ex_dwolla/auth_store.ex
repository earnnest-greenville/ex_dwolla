defmodule ExDwolla.AuthStore do
  @moduledoc false

  use GenServer
  alias ExDwolla.Application
  alias ExDwolla.Utils

  defstruct [
    :key,
    :secret,
    :access_token,
    :access_token_type,
    environment: "dev"
  ]

  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def get_token(), do: GenServer.call(__MODULE__, :get_token)

  def get_environment(), do: GenServer.call(__MODULE__, :get_environment)

  @impl true
  def init(%{environment: environment, key: key, secret: secret}) do
    Process.flag(:trap_exit, true)
    state = %__MODULE__{environment: environment, key: key, secret: secret}
    {:ok, {state1, expires_in}} = refresh_access_token(state)
    {:ok, state1, seconds_to_timeout(expires_in)}
  end

  @impl true
  def handle_call(:get_token, _, %__MODULE__{access_token: access_token, access_token_type: access_token_type} = state) do
    {:reply, %{token: access_token, token_type: access_token_type}, state}
  end

  @impl true
  def handle_call(:get_environment, _, %__MODULE__{environment: environment} = state) do
    {:reply, environment, state}
  end

  @impl true
  def handle_info(:timeout, %__MODULE__{} = state) do
    case refresh_access_token(state) do
      {:ok, {state1, expires_in}} -> {:noreply, state1, seconds_to_timeout(expires_in)}
      {:error, error} -> {:stop, error, state}
    end
  end

  @impl true
  def code_change(_, %__MODULE__{} = state, _), do: {:ok, state}

  defp refresh_access_token(%__MODULE__{environment: environment, key: key, secret: secret} = state) do
    domain = Utils.base_auth_domain(environment)

    credentials = Base.encode64("#{key}:#{secret}")
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Basic #{credentials}"}
    ]

    with {:ok, %Mojito.Response{body: body}} <- Application.http_client.request(
                                                  method: :post,
                                                  url: "https://" <> domain <> "/token",
                                                  headers: headers,
                                                  body: "grant_type=client_credentials"
                                                ),
         {:ok, %{"access_token" => access_token, "expires_in" => expires_in, "token_type" => token_type}} <- Jason.decode(body)
    do
      {:ok, {%__MODULE__{state | access_token: access_token, access_token_type: token_type}, expires_in}}
    else
      error -> error
    end
  end

  defp seconds_to_timeout(seconds), do: (seconds - 10) * 10000
end