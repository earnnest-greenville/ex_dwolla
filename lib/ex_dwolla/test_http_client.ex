defmodule ExDwolla.TestHttpClient do
  @moduledoc false

  def request(method: :post, url: "https://accounts-sandbox.dwolla.com/token", headers: _headers, body: _body) do
    {:ok, body} = Jason.encode(%{access_token: "abc", expires_in: 3160, token_type: "test"})
    {:ok, %Mojito.Response{body: body}}
  end

  def request(method: :get, url: "https://api-sandbox.dwolla.com/", headers: _headers, body: _body) do
    {:ok, body} = Jason.encode(%{_links: %{account: %{href: "https://api-sandbox.dwolla.com/accounts/some_id"}}})
    {:ok, %Mojito.Response{body: body, status_code: 200}}
  end

  def request(method: :get, url: "https://api-sandbox.dwolla.com/accounts/some_account_id", headers: _headers, body: _body) do
    data = %{
      _links: %{
        self: %{
          href: "https://api-sandbox.dwolla.com/accounts/some_account_id"
        }
      },
      id: "some_account_id",
      name: "Your Test Account",
    }

    {:ok, body} = Jason.encode(data)
    {:ok, %Mojito.Response{body: body, status_code: 200}}
  end

  def request(method: :post, url: "https://api-sandbox.dwolla.com/funding-sources", headers: _headers, body: "{\"accountNumber\":\"1\",\"bankAccountType\":\"checking\",\"routingNumber\":\"1\"}") do
    {:ok, %Mojito.Response{
      body: "",
      status_code: 201,
      headers: [{"location", "https://api-sandbox.dwolla.com/funding-sources/new_funding_source_id"}]
    }}
  end

  def request(method: :get, url: "https://api-sandbox.dwolla.com/accounts/some_account_id/funding-sources?removed=false", headers: _headers, body: _body) do
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
    {:ok, %Mojito.Response{body: body, status_code: 200}}
  end
end