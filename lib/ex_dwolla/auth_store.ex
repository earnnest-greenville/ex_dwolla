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
    Process.send_after(self(), :refresh_access_token, seconds_to_timeout(expires_in))
    {:ok, state1}
  end

  @impl true
  def handle_call(
        :get_token,
        _,
        %__MODULE__{access_token: access_token, access_token_type: access_token_type} = state
      ) do
    {:reply, %{token: access_token, token_type: access_token_type}, state}
  end

  @impl true
  def handle_call(:get_environment, _, %__MODULE__{environment: environment} = state) do
    {:reply, environment, state}
  end

  @impl true
  def handle_info(:refresh_access_token, %__MODULE__{} = state) do
    case refresh_access_token(state) do
      {:ok, {state1, expires_in}} ->
        Process.send_after(self(), :refresh_access_token, seconds_to_timeout(expires_in))
        {:noreply, state1}

      {:error, error} ->
        {:stop, error, state}
    end
  end

  @impl true
  def code_change(_, %__MODULE__{} = state, _), do: {:ok, state}

  defp refresh_access_token(
         %__MODULE__{environment: environment, key: key, secret: secret} = state
       ) do
    domain = Utils.base_api_domain(environment)
    url = 'https://' ++ to_charlist(domain) ++ '/token'

    credentials = Base.encode64("#{key}:#{secret}")

    headers = [
      {'Content-Type', 'application/x-www-form-urlencoded'},
      {'Authorization', 'Basic ' ++ to_charlist(credentials)}
    ]

    with {:ok, {{_, 200, _status}, _headers, body}} <-
           Application.http_client().request(
             :post,
             {url, headers, 'application/x-www-form-urlencoded', 'grant_type=client_credentials'},
             [],
             []
           ),
         {:ok,
          %{
            "access_token" => access_token,
            "expires_in" => expires_in,
            "token_type" => token_type
          }} <- Jason.decode(body) do
      {:ok,
       {%__MODULE__{state | access_token: access_token, access_token_type: token_type},
        expires_in}}
    else
      error -> error
    end
  end

  defp seconds_to_timeout(seconds), do: (seconds - 10) * 1_000
end
