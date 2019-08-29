defmodule ExDwolla.Utils do
  @moduledoc """
  Utilities for working with other areas of ExDwolla.
  """
  @moduledoc since: "0.0.1"

  @doc """
  Given the environment, return the Dwolla authentication domain.

  ## Example
      iex> ExDwolla.Utils.base_auth_domain("dev")
      "accounts-sandbox.dwolla.com"

      iex> ExDwolla.Utils.base_auth_domain("prod")
      "accounts.dwolla.com"
  """
  @doc since: "0.0.1"
  def base_auth_domain(environment)
  def base_auth_domain("dev"), do: "accounts-sandbox.dwolla.com"
  def base_auth_domain(_), do: "accounts.dwolla.com"

  @doc """
  Given the environment, return the Dwolla API domain.

  ## Example
      iex> ExDwolla.Utils.base_api_domain("dev")
      "api-sandbox.dwolla.com"

      iex> ExDwolla.Utils.base_api_domain("prod")
      "api.dwolla.com"
  """
  @doc since: "0.0.1"
  def base_api_domain(environment)
  def base_api_domain("dev"), do: "api-sandbox.dwolla.com"
  def base_api_domain(_), do: "api.dwolla.com"

  @doc """
  Convert the case of the keys of a given Map, Keyword List, or Key-Value Pair.

  ## Example
      iex> ExDwolla.Utils.recase(%{test_one: 1, test_two: 2}, :camel)
      %{"testOne" => 1, "testTwo" => 2}

      iex> ExDwolla.Utils.recase([{:test_one, 1}, {:test_two, 2}], :camel)
      [{"testOne", 1}, {"testTwo", 2}]

      iex> ExDwolla.Utils.recase({:welcome_message, "Hello World!"}, :camel)
      {"welcomeMessage", "Hello World!"}

      iex> ExDwolla.Utils.recase(%{"allUsers" => [%{"firstName" => "Joe", "lastName" => "Armstrong"}]}, :snake)
      %{all_users: [%{first_name: "Joe", last_name: "Armstrong"}]}
  """
  @doc since: "0.0.1"
  def recase(%{} = map, switch_to) do
    map
    |> Map.delete(:__struct__)
    |> Map.to_list()
    |> Map.new((&recase(&1, switch_to)))
  end

  def recase({k, v}, switch_to) when is_atom(k) do
    recase({Atom.to_string(k), v}, switch_to)
  end

  def recase({"_" <> k, v}, :camel) do
    {"_" <> recase(k, :camel), v}
  end

  def recase({k, v}, :camel) when is_map(v), do: {camelize(k), recase(v, :camel)}

  def recase({k, v}, :camel) when is_list(v), do: {camelize(k), v |> Enum.map((&recase(&1, :camel)))}

  def recase({k, v}, :camel), do: {camelize(k), v}

  def recase({k, v}, :snake) when is_map(v), do: {snakerize(k), recase(v, :snake)}

  def recase({k, v}, :snake) when is_list(v), do: {snakerize(k), v |> Enum.map((&recase(&1, :snake)))}

  def recase({k, v}, :snake), do: {snakerize(k), v}

  def recase(v, switch_to) when is_list(v), do: v |> Enum.map((&recase(&1, switch_to)))

  def recase(s, _switch_to) when is_bitstring(s), do: s

  @doc """
  Given snake-cased string, convert it to camel-case.

  ## Example
      iex> ExDwolla.Utils.camelize("test_one")
      "testOne"

      iex> ExDwolla.Utils.camelize("test_two")
      "testTwo"
  """
  @doc since: "0.0.1"
  def camelize(s) when is_bitstring(s) do
    pascalCased = Macro.camelize(s)

    first = pascalCased |> String.first
    lower = first |> String.downcase

    pascalCased |> String.replace(first, lower, global: false)
  end

  @doc """
  Given a camel-case string, convert it to snake-case.

  ## Example
      iex> ExDwolla.Utils.snakerize("testOne")
      :test_one

      iex> ExDwolla.Utils.snakerize("testTwo")
      :test_two
  """
  @doc since: "0.0.1"
  def snakerize(s), do: s |> String.replace("-", "_") |> Macro.underscore |> String.to_atom

  @doc """
  Strip any key from the given map if the value is nil.

  ## Example
      iex> ExDwolla.Utils.strip_nils(%{message1: "Hello, World!", message2: nil, message3: "Foo"})
      %{message1: "Hello, World!", message3: "Foo"}
  """
  @doc since: "0.0.1"
  def strip_nils(m), do: m |> Enum.filter(fn {_k, v} -> v !== nil end) |> Map.new

  @doc """
  Given a list of HTTP Response headers, extract and return the location

  ## Example
      iex> ExDwolla.Utils.get_location_from_headers([{"content-type", "application/json"}, {"location", "test_url"}])
      {:ok, "test_url"}

      iex> ExDwolla.Utils.get_location_from_headers([{"content-type", "appliation/json"}, {"accept", "gzip"}])
      {:error, "No location found in headers."}
  """
  @doc since: "0.0.1"
  def get_location_from_headers([{"location", location} | _]) do
    {:ok, location}
  end

  def get_location_from_headers([_ | rest]), do: get_location_from_headers(rest)

  def get_location_from_headers([]) do
    {:error, "No location found in headers."}
  end

  @doc """
  Convert a map to a query string

  ## Example
      iex> ExDwolla.Utils.map_to_query_string(%{page: 5, limit: 10, filter: "abc"})
      "page=5&limit=10&filter=abc"

      iex> ExDwolla.Utils.map_to_query_string(%{page: 5, limit: 10, filter: nil})
      "page=5&limit=10"
  """
  @doc since: "0.0.1"
  def map_to_query_string(%{} = map) do
    map
    |> recase(:camel)
    |> strip_nils()
    |> Enum.reduce("", fn({k, v}, agg) -> to_string(k) <> "=" <> to_string(v) <> "&" <> agg end)
    |> String.trim_trailing("&")
  end

  @doc """
  Convert a keyword list or tuple from strings to charlists

  ## Example
      iex> ExDwolla.Utils.to_charlists({"message", "Hello, World!"})
      {'message', 'Hello, World!'}

      iex> ExDwolla.Utils.to_charlists([{"message1", "Hello, World!"}, {"message2", "Goodbye!"}])
      [{'message1', 'Hello, World!'}, {'message2', 'Goodbye!'}]
  """
  @doc since: "0.0.1"
  def to_charlists({key, value}) when is_bitstring(key) and is_bitstring(value) do
    {to_charlist(key), to_charlist(value)}
  end

  def to_charlists(keyword_list) when is_list(keyword_list) do
    keyword_list
    |> Enum.map(&to_charlists/1)
  end

  @doc """
  Convert a keyword list or tuple from charlists to strings

  ## Example
      iex> ExDwolla.Utils.to_strings({'message', 'Hello, World!'})
      {"message", "Hello, World!"}

      iex> ExDwolla.Utils.to_strings([{'message1', 'Hello, World!'}, {'message2', 'Goodbye!'}])
      [{"message1", "Hello, World!"}, {"message2", "Goodbye!"}]
  """
  @doc since: "0.0.1"
  def to_strings({key, value}) when is_list(key) and is_list(value) do
    {to_string(key), to_string(value)}
  end

  def to_strings(keyword_list) when is_list(keyword_list) do
    keyword_list
    |> Enum.map(&to_strings/1)
  end
end