defmodule ExDwolla.Core do
  require Logger

  alias ExDwolla.AuthStore
  alias ExDwolla.Application
  alias ExDwolla.Utils

  def base_request(
        method,
        url_or_path,
        headers,
        data \\ "",
        attempts \\ 5,
        content_type \\ "application/x-www-form-urlencoded"
      )

  def base_request(_, _, _, _, 0, _), do: {:error, "Exhausted Dwolla request retry attempts"}

  def base_request(method, url_or_path, headers, data, attempts, content_type)
      when is_map(data) do
    encoded =
      data
      |> Utils.recase(:camel)
      |> Utils.strip_nils()
      |> Map.delete("struct")
      |> Jason.encode()

    case encoded do
      {:ok, body} -> base_request(method, url_or_path, headers, body, attempts, content_type)
      _ -> {:error, "Unable to convert data to JSON text"}
    end
  end

  def base_request(method, url_or_path, headers, body, attempts, content_type)
      when is_bitstring(body) do
    environment = AuthStore.get_environment()
    %{token: token, token_type: token_type} = AuthStore.get_token()
    domain = Utils.base_api_domain(environment)
    base_headers = base_headers(method, token, token_type, domain)
    all_headers = merge_headers(base_headers, headers)
    url = build_url!(domain, url_or_path)

    r = perform_request(method, url, all_headers, body, content_type)

    case r do
      {:ok, {{_, 201, _}, headers, ""}} ->
        {:ok, %{}, Utils.to_strings(headers)}

      {:ok, {{_, 200, _}, headers, response_body}} ->
        snaked = response_body |> to_string() |> Jason.decode!() |> Utils.recase(:snake)
        {:ok, snaked, headers}

      {:ok, {{_, status_code, _}, _headers, ""}} ->
        Logger.debug("Got response code with empty body from Dwolla: #{status_code}.")
        {:error, {status_code, ""}}

      {:ok, {{_, status_code, _}, _headers, response_body}} ->
        Logger.debug("Got response_code from Dwolla: #{status_code}.")
        Logger.debug("With response body: #{response_body}")
        snaked = response_body |> to_string() |> Jason.decode!() |> Utils.recase(:snake)
        {:error, {status_code, snaked}}

      {:error, {:failed_connect, _}} ->
        Logger.debug("Failed to connect, retrying #{attempts - 1} more times.")
        base_request(method, url_or_path, headers, body, attempts - 1)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def base_request(_, _, _, _, _, _), do: {:error, "Unsupported data type specified for request"}

  def get_request(path, request_headers \\ []) do
    case base_request(:get, path, request_headers) do
      {:ok, body, _headers} -> {:ok, body}
      error -> error
    end
  end

  def create_request(path, data, request_headers \\ []) do
    with {:ok, _body, response_headers} <- base_request(:post, path, request_headers, data),
         {:ok, location} <- Utils.get_location_from_headers(response_headers) do
      id = location |> String.split("/") |> Enum.at(-1)
      {:ok, id}
    end
  end

  def update_request(path, data, request_headers \\ []) do
    case base_request(:post, path, request_headers, data) do
      {:ok, body, _headers} -> {:ok, body}
      error -> error
    end
  end

  def delete_request(path, request_headers \\ []) do
    case base_request(:delete, path, request_headers) do
      {:ok, _body, _headers} -> {:ok}
      error -> error
    end
  end

  def upload_document_request(path, filename, file_path_or_binary, extra_data) do
    with {:ok, file} <- File.read(file_path_or_binary),
         {boundary, data} <- format_multipart_data("file", filename, file, extra_data),
         content_type <- "multipart/form-data; boundary=#{boundary}",
         {:ok, _body, headers} <-
           base_request(:post, path, [{"Content-Type", content_type}], data, 5, content_type),
         {:ok, location} <- Utils.get_location_from_headers(headers) do
      id = location |> String.split("/") |> Enum.at(-1)
      {:ok, id}
    end
  end

  defp base_headers(:post, token, token_type, domain) do
    [
      {"host", domain},
      {"Content-Type", "application/vnd.dwolla.v1.hal+json"},
      {"Accept", "application/vnd.dwolla.v1.hal+json"},
      {"Authorization", "#{token_type} #{token}"},
      {"Idempotency-Key", UUID.uuid4()}
    ]
  end

  defp base_headers(_, token, token_type, _domain) do
    [
      {"Content-Type", "application/vnd.dwolla.v1.hal+json"},
      {"Accept", "application/vnd.dwolla.v1.hal+json"},
      {"Authorization", "#{token_type} #{token}"}
    ]
  end

  def build_url!(domain, "https://" <> rest = url) do
    case String.starts_with?(rest, domain) do
      true -> url
      _ -> raise("Invalid URL requested!")
    end
  end

  def build_url!(domain, "/" <> _rest = path), do: "https://" <> domain <> path

  def build_url!(domain, path), do: build_url!(domain, "/" <> path)

  defp perform_request(:get, url, headers, _body, _content_type) do
    Application.http_client().request(
      :get,
      {to_charlist(url), Utils.to_charlists(headers)},
      [timeout: Application.request_timeout()],
      []
    )
  end

  defp perform_request(:delete, url, headers, _body, _content_type) do
    Application.http_client().request(
      :delete,
      {to_charlist(url), Utils.to_charlists(headers)},
      [timeout: Application.request_timeout()],
      []
    )
  end

  defp perform_request(method, url, headers, body, content_type) do
    content_length = body |> :erlang.byte_size() |> to_string()

    headers1 =
      merge_headers(headers, [{"content-length", content_length}, {"connection", "keep-alive"}])

    Application.http_client().request(
      method,
      {to_charlist(url), Utils.to_charlists(headers1), to_charlist(content_type), body},
      [timeout: Application.request_timeout()],
      headers_as_is: true,
      body_format: :binary
    )
  end

  defp format_multipart_data(name, filename, file, extra_data) do
    boundary = "-------------------------" <> UUID.uuid4()
    line_separator = "\r\n"
    start = "--#{boundary}"
    mime_type = filename |> String.split(".") |> Enum.at(-1) |> mime_type!()

    base_body =
      extra_data
      |> Utils.recase(:camel)
      |> Utils.strip_nils()
      |> Map.delete("struct")
      |> Enum.reduce(<<>>, fn {k, v}, agg ->
        agg <>
          start <>
          line_separator <>
          "Content-Disposition: form-data; name=\"#{k}\"" <>
          line_separator <>
          "Content-Type: text/plain" <>
          line_separator <>
          line_separator <>
          "#{v}" <> line_separator
      end)

    body =
      base_body <>
        start <>
        line_separator <>
        "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{filename}\"" <>
        line_separator <>
        "Content-Type: " <>
        mime_type <>
        line_separator <>
        line_separator <>
        file <>
        line_separator <>
        start <> "--" <> line_separator

    {boundary, body}
  end

  defp merge_headers(base_headers, new_headers) do
    base_headers1 =
      base_headers |> Enum.map(fn {k, v} -> {String.to_atom(String.downcase(k)), v} end)

    new_headers1 =
      new_headers |> Enum.map(fn {k, v} -> {String.to_atom(String.downcase(k)), v} end)

    merged = Keyword.merge(base_headers1, new_headers1)
    merged |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
  end

  defp mime_type!("pdf"), do: "application/pdf"

  defp mime_type!("jpg"), do: "image/jpeg"

  defp mime_type!("jpeg"), do: "image/jpeg"

  defp mime_type!("png"), do: "image/png"

  defp mime_type!(_), do: raise("Unsupported File Type!")
end
