defmodule ExDwolla.Core do
  require Logger

  alias ExDwolla.AuthStore
  alias ExDwolla.Application
  alias ExDwolla.Utils

  def base_request(method, url_or_path, headers, data \\ "", attempts \\ 5)

  def base_request(_, _, _, _, 0), do: {:error, "Exhausted Dwolla request retry attempts"}

  def base_request(method, url_or_path, headers, data, attempts) when is_map(data) do
    encoded = data
    |> Utils.recase(:camel)
    |> Utils.strip_nils()
    |> Map.delete("struct")
    |> Jason.encode()

    case encoded do
      {:ok, body} -> base_request(method, url_or_path, headers, body, attempts)
      _ -> {:error, "Unable to convert data to JSON text"}
    end
  end

  def base_request(method, url_or_path, headers, body, attempts) when is_bitstring(body) do
    environment = AuthStore.get_environment()
    %{token: token, token_type: token_type} =  AuthStore.get_token()
    domain = Utils.base_api_domain(environment)
    base_headers = base_headers(method, token, token_type)
    url = build_url!(domain, url_or_path)

    r = Application.http_client.request(method: method, url: url, headers: base_headers ++ headers, body: body)

    case r do
      {:ok, %Mojito.Response{body: "", headers: headers, status_code: 201}} -> {:ok, %{}, headers}
      {:ok, %Mojito.Response{body: body, headers: headers, status_code: 200}} ->
        snaked = body |> Jason.decode!() |> Utils.recase(:snake)
        {:ok, snaked, headers}
      {:ok, %Mojito.Response{body: body, status_code: status_code}} ->
        Logger.debug("Got response_code from Dwolla: #{status_code}.")
        snaked = body |> Jason.decode!() |> Utils.recase(:snake)
        {:error, {status_code, snaked}}
      {:error, %Mojito.Error{reason: :timeout}} ->
          base_request(method, url_or_path, headers, body, attempts - 1)
      {:error, error} -> {:error, error}
    end
  end

  def base_request(_, _, _, _, _), do: {:error, "Unsupported data type specified for request"}

  def get_request(path) do
    case base_request(:get, path, []) do
      {:ok, body, _headers} -> {:ok, body}
      error -> error
    end
  end

  def create_request(path, data) do
    with {:ok, _body, headers} <- base_request(:post, path, [], data),
         {:ok, location} <- Utils.get_location_from_headers(headers)
    do
      id = location |> String.split("/") |> Enum.at(-1)
      {:ok, id}
    else
      error -> error
    end
  end

  defp base_headers(:post, token, token_type) do
    [
      {"Content-Type", "application/vnd.dwolla.v1.hal+json"},
      {"Accept", "application/vnd.dwolla.v1.hal+json"},
      {"Authorization", "#{token_type} #{token}"},
      {"Idempotency-Key", UUID.uuid4()}
    ]
  end

  defp base_headers(_, token, token_type) do
    [
      {"Content-Type", "application/vnd.dwolla.v1.hal+json"},
      {"Accept", "application/vnd.dwolla.v1.hal+json"},
      {"Authorization", "#{token_type} #{token}"}
    ]
  end

  defp build_url!(domain, "https://" <> rest = url) do
    case String.starts_with?(rest, domain) do
      true -> url
      _ -> raise("Invalid URL requested!")
    end
  end

  defp build_url!(domain, "/" <> _rest = path), do: "https://" <> domain <> path

  defp build_url!(domain, path), do: build_url!(domain, "/" <> path)
end