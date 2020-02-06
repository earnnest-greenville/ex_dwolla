defmodule ExDwolla do
  @moduledoc """
  The root Dwolla API functionality.
  """
  @moduledoc since: "0.1.0"

  alias ExDwolla.Core

  @doc """
  Get the root details for your Dwolla Account

  ## Example
      iex> ExDwolla.root()
      {:ok, %{_links: %{account: %{href: "https://api-sandbox.dwolla.com/accounts/some_id"}}}}
  """
  @doc since: "0.1.0"
  def root(), do: Core.get_request("/")
end

defmodule ExDwolla.Accounts do
  @moduledoc """
  Account related Dwolla API functionality.
  """
  @moduledoc since: "0.0.1"

  alias ExDwolla.Core
  alias ExDwolla.Requests
  alias ExDwolla.Utils

  @doc """
  Get the account details for a given id

  ## Example
      iex> ExDwolla.Accounts.get("some_account_id")
      {
        :ok,
        %{
          _links: %{
            self: %{
              href: "https://api-sandbox.dwolla.com/accounts/some_account_id"
            }
          },
          id: "some_account_id",
          name: "Your Test Account"
        }
      }
  """
  @doc since: "0.0.1"
  def get(account_id),
    do: Core.get_request("/accounts/#{account_id}")

  @doc """
  Create a new Funding Source

  ## Example
      iex> funding_source = %ExDwolla.Requests.CreateFundingSource{
      ...>   routing_number: "1",
      ...>   account_number: "1",
      ...>   bank_account_type: "checking"
      ...> }
      iex> ExDwolla.Accounts.create_funding_source(funding_source)
      {:ok, "new_funding_source_id"}
  """
  @doc since: "0.0.1"
  def create_funding_source(%Requests.CreateFundingSource{} = funding_source),
    do: Core.create_request("/funding-sources", funding_source)

  @doc """
  Get your Funding Sources

  ## Example
      iex> ExDwolla.Accounts.get_funding_sources("some_account_id")
      {
        :ok,
        %{
          _links: %{
            self: %{
              href: "https://api-sandbox.dwolla.com/accounts/some_account_id/funding-sources",
              resource_type: "funding-source"
            }
          },
          _embedded: %{
            funding_sources: [
              %{
                _links: %{
                  self: %{
                    href: "https://api-sandbox.dwolla.com/funding-sources/some_funding_source_id"
                  }
                },
                id: "some_funding_source_id",
                status: "verified",
                type: "bank",
                bank_account_type: "checking",
                name: "My Checking Account",
                created: "2017-09-25T20:03:41.000Z",
                removed: false
              }
            ]
          }
        }
      }
  """
  @doc since: "0.0.1"
  def get_funding_sources(account_id, is_removed_filtered \\ false),
    do: Core.get_request("/accounts/#{account_id}/funding-sources?removed=#{is_removed_filtered}")

  def get_transfers(account_id, %Requests.GetTransfersForAccount{} = params \\ %Requests.GetTransfersForAccount{}) do
    query_string = Utils.map_to_query_string(params)
    Core.get_request("/accounts/#{account_id}/transfers?#{query_string}")
  end
end

defmodule ExDwolla.Customers do
  @moduledoc """
  Customer related Dwolla API Functionality
  """
  @moduledoc since: "0.0.1"

  alias ExDwolla.Core
  alias ExDwolla.Requests
  alias ExDwolla.Utils

  def get_all(%Requests.GetCustomers{} = params \\ %Requests.GetCustomers{}) do
    query_string = Utils.map_to_query_string(params)
    url = case query_string do
      "" -> "/customers"
      _ -> "/customers?#{query_string}"
    end
    Core.get_request(url)
  end

  def get(customer_id), do: Core.get_request("/customers/#{customer_id}")

  @doc """
  Create a new Customer

  ## Example
      iex> customer = %ExDwolla.Requests.Customer.Create{
      ...>   first_name: "Earnnest",
      ...>   last_name: "Developer",
      ...> }
      iex> ExDwolla.Customers.create(customer)
      {:ok, "new_customer_id"}
  """
  @doc since: "0.0.1"
  def create(%Requests.Customer.Create{} = customer),
    do: Core.create_request("/customers", customer)

  @doc since: "0.0.1"
  def update(%Requests.Customer.Update{} = customer, customer_id),
    do: Core.update_request("/customers/#{customer_id}", customer)

  @doc since: "0.0.1"
  def create_funding_source(%Requests.Customer.CreateFundingSource{} = funding_source, customer_id),
    do: Core.create_request("/customers/#{customer_id}/funding-sources", funding_source)

  @doc since: "0.0.1"
  def create_iav_token(customer_id),
    do: Core.update_request("/customers/#{customer_id}/iav-token", "")

  @doc since: "0.0.1"
  def create_funding_source_token(customer_id),
    do: Core.update_request("/customers/#{customer_id}/funding-sources-token", "")

  def upload_document(%Requests.UploadDocument{
    customer_id: customer_id,
    filename: filename,
    path: path,
    document_type: document_type
  }), do: Core.upload_document_request("/customers/#{customer_id}/documents", filename, path, %{documentType: document_type})
end

defmodule ExDwolla.FundingSources do
  @moduledoc """
  Funding Source related Dwolla API Functionality
  """
  @moduledoc since: "0.0.1"

  alias ExDwolla.Core
  alias ExDwolla.Requests
  alias ExDwolla.Utils

  def get(funding_source_id), do: Core.get_request("/funding-sources/#{funding_source_id}")

  def remove(funding_source_id),
    do: Core.update_request("/funding-sources/#{funding_source_id}", %{removed: true})

  def get_microdeposits(funding_source_id), do: Core.get_request("/funding-sources/#{funding_source_id}/micro-deposits")
end

defmodule ExDwolla.Transfers do
  @moduledoc """
  Transfer related Dwolla API Functionality
  """
  @moduledoc since: "0.0.1"

  alias ExDwolla.Core
  alias ExDwolla.Requests
  alias ExDwolla.Utils

  def get(transfer_id), do: Core.get_request("/transfers/#{transfer_id}")

  def create(%Requests.Transfers.Create{} = transfer, idempotency_key),
    do: Core.update_request("/transfers", transfer, [{"Idempotency-Key", idempotency_key}])
end

defmodule ExDwolla.WebhookSubscriptions do
  @moduledoc """
  Webhook related Dwolla API Functionality
  """
  @moduledoc since: "0.0.1"

  alias ExDwolla.Core
  alias ExDwolla.Requests
  alias ExDwolla.Utils

  def create(%Requests.WebhookSubscriptions.Create{} = webhook_subscription),
    do: Core.create_request("/webhook-subscriptions", webhook_subscription)

  def delete(webhook_subscription_id),
    do: Core.delete_request("/webhook_subscriptions/#{webhook_subscription_id}")
end
