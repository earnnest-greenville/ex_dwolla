defmodule ExDwolla.TestHttpClient do
  @moduledoc false

  def request(
        :post,
        {~c"https://api-sandbox.dwolla.com/token", _headers, _content_type, _body},
        _http_opts,
        []
      ) do
    {:ok, body} = Jason.encode(%{access_token: "abc", expires_in: 3160, token_type: "test"})
    {:ok, {{~c"HTTP/1.1", 200, ~c"OK"}, [], to_charlist(body)}}
  end

  def request(:get, {~c"https://api-sandbox.dwolla.com/", _headers}, _http_opts, []) do
    {:ok, body} =
      Jason.encode(%{
        _links: %{account: %{href: "https://api-sandbox.dwolla.com/accounts/some_id"}}
      })

    {:ok, {{~c"HTTP/1.1", 200, ~c"OK"}, [], to_charlist(body)}}
  end

  def request(
        :get,
        {~c"https://api-sandbox.dwolla.com/accounts/some_account_id", _headers},
        _http_opts,
        []
      ) do
    data = %{
      _links: %{
        self: %{
          href: "https://api-sandbox.dwolla.com/accounts/some_account_id"
        }
      },
      id: "some_account_id",
      name: "Your Test Account"
    }

    {:ok, body} = Jason.encode(data)
    {:ok, {{~c"HTTP/1.1", 200, ~c"OK"}, [], to_charlist(body)}}
  end

  def request(
        :post,
        {~c"https://api-sandbox.dwolla.com/funding-sources", _headers, _content_type,
         "{\"accountNumber\":\"1\",\"bankAccountType\":\"checking\",\"routingNumber\":\"1\"}"},
        _http_opts,
        _opts
      ) do
    {:ok,
     {{~c"HTTP/1.1", 201, ~c"OK"},
      [{~c"location", ~c"https://api-sandbox.dwolla.com/funding-sources/new_funding_source_id"}],
      ""}}
  end

  def request(
        :post,
        {~c"https://api-sandbox.dwolla.com/customers", _headers, _content_type,
         "{\"firstName\":\"Earnnest\",\"lastName\":\"Developer\"}"},
        _http_opts,
        _opts
      ) do
    {:ok,
     {{~c"HTTP/1.1", 201, ~c"OK"},
      [{~c"location", ~c"https://api-sandbox.dwolla.com/customers/new_customer_id"}], ""}}
  end

  def request(
        :get,
        {~c"https://api-sandbox.dwolla.com/accounts/some_account_id/funding-sources?removed=false",
         _headers},
        _http_opts,
        []
      ) do
    data = %{
      "_links" => %{
        "self" => %{
          "href" => "https://api-sandbox.dwolla.com/accounts/some_account_id/funding-sources",
          "resource-type" => "funding-source"
        }
      },
      "_embedded" => %{
        "funding-sources" => [
          %{
            "_links" => %{
              "self" => %{
                "href" => "https://api-sandbox.dwolla.com/funding-sources/some_funding_source_id"
              }
            },
            "id" => "some_funding_source_id",
            "status" => "verified",
            "type" => "bank",
            "bankAccountType" => "checking",
            "name" => "My Checking Account",
            "created" => "2017-09-25T20:03:41.000Z",
            "removed" => false
          }
        ]
      }
    }

    {:ok, body} = Jason.encode(data)
    {:ok, {{~c"HTTP/1.1", 200, ~c"OK"}, [], to_charlist(body)}}
  end
end
