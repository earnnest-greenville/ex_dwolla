defmodule ExDwolla.Core do
  require Logger

  alias ExDwolla.AuthStore
  alias ExDwolla.Application
  alias ExDwolla.Utils

  def base_request(method, url_or_path, headers, data \\ "", attempts \\ 5, content_type \\ "application/x-www-form-urlencoded")

  def base_request(_, _, _, _, 0, _), do: {:error, "Exhausted Dwolla request retry attempts"}

  def base_request(method, url_or_path, headers, data, attempts, content_type) when is_map(data) do
    encoded = data
    |> Utils.recase(:camel)
    |> Utils.strip_nils()
    |> Map.delete("struct")
    |> Jason.encode()

    case encoded do
      {:ok, body} -> base_request(method, url_or_path, headers, body, attempts, content_type)
      _ -> {:error, "Unable to convert data to JSON text"}
    end
  end

  def base_request(method, url_or_path, headers, body, attempts, content_type) when is_bitstring(body) do
    environment = AuthStore.get_environment()
    %{token: token, token_type: token_type} =  AuthStore.get_token()
    domain = Utils.base_api_domain(environment)
    base_headers = base_headers(method, token, token_type, domain)
    url = build_url!(domain, url_or_path)

    r = perform_request(method, url, base_headers ++ headers, body, content_type)

    case r do
      {:ok, {{_, 201, _}, headers, ''}} -> {:ok, %{}, Utils.to_strings(headers)}
      {:ok, {{_, 200, _}, headers, body}} ->
        snaked = body |> to_string() |> Jason.decode!() |> Utils.recase(:snake)
        {:ok, snaked, headers}
      {:ok, {{_, status_code, _}, _headers, body}} ->
        Logger.debug("Got response_code from Dwolla: #{status_code}.")
        Logger.debug(body)
        snaked = body |> to_string() |> Jason.decode!() |> Utils.recase(:snake)
        {:error, {status_code, snaked}}
      {:error, {:failed_connect, _}} ->
        Logger.debug("Failed to connect, retrying #{attempts - 1} more times.")
        base_request(method, url_or_path, headers, body, attempts - 1)
      {:error, reason} -> {:error, reason}
    end
  end

  def base_request(_, _, _, _, _, _), do: {:error, "Unsupported data type specified for request"}

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

  defp base_headers(:post, token, token_type, domain) do
    [
      {"Content-Type", "application/vnd.dwolla.v1.hal+json"},
      {"Accept", "application/vnd.dwolla.v1.hal+json"},
      {"Authorization", "#{token_type} #{token}"},
      {"Idempotency-Key", UUID.uuid4()},
      {"host", domain}
    ]
  end

  defp base_headers(_, token, token_type, _domain) do
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

  defp perform_request(:get, url, headers, _body, _content_type) do
    Application.http_client.request(:get, {to_charlist(url), Utils.to_charlists(headers)}, [timeout: 10_000], [])
  end

  defp perform_request(method, url, headers, body, content_type) do
    body1 = to_charlist(body)
    content_length = body1 |> length() |> to_string()
    headers1 = headers ++ [{"content-length", content_length}, {"connection", "keep-alive"}]

    Application.http_client.request(
      method,
      {to_charlist(url), Utils.to_charlists(headers1), to_charlist(content_type), body1},
      [timeout: 10_000],
      [headers_as_is: true])
  end
end