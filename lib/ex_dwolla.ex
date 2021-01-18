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
  @spec root() :: map()
  def root(), do: Core.get_request("/")
end

defmodule ExDwolla.Accounts do
  @moduledoc """
  Account related Dwolla API functionality.
  """
  @moduledoc since: "0.0.1"

  @type id() :: String.t()

  @type create_funding_source_request :: %{
          routing_number: String.t(),
          account_number: String.t(),
          bank_acount_type: String.t(),
          name: String.t(),
          channels: list(String.t())
        }

  @type get_transfers_for_account_request :: %{
          search: String.t(),
          start_amount: String.t(),
          end_amount: String.t(),
          start_date: String.t(),
          end_date: String.t(),
          status: String.t(),
          correlation_id: String.t(),
          limit: integer,
          offset: integer
        }

  @type error :: {:error, {integer, String.t()}} | {:error, any()}

  @type create_response :: {:ok, String.t()} | error

  @type response :: {:ok, map()} | error

  alias ExDwolla.Core
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
  @spec get(id()) :: response()
  def get(account_id),
    do: Core.get_request("/accounts/#{account_id}")

  @doc """
  Create a new Funding Source

  ## Example
      iex> funding_source = %{
      ...>   routing_number: "1",
      ...>   account_number: "1",
      ...>   bank_account_type: "checking"
      ...> }
      iex> ExDwolla.Accounts.create_funding_source(funding_source)
      {:ok, "new_funding_source_id"}
  """
  @doc since: "0.0.1"
  @spec create_funding_source(create_funding_source_request()) :: create_response()
  def create_funding_source(%{} = funding_source),
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
  @spec get_funding_sources(id(), boolean()) :: response()
  def get_funding_sources(account_id, is_removed_filtered \\ false),
    do: Core.get_request("/accounts/#{account_id}/funding-sources?removed=#{is_removed_filtered}")

  @doc since: "0.0.1"
  @spec get_transfers(id(), get_transfers_for_account_request()) :: response()
  def get_transfers(account_id, params \\ %{}) do
    query_string = Utils.map_to_query_string(params)
    Core.get_request("/accounts/#{account_id}/transfers?#{query_string}")
  end
end

defmodule ExDwolla.Customers do
  @moduledoc """
  Customer related Dwolla API Functionality
  """
  @moduledoc since: "0.0.1"

  @type id() :: String.t()

  @type controller_address :: %{
          :address1 => String.t(),
          optional(:address2) => String.t(),
          optional(:address3) => String.t(),
          :city => String.t(),
          :state_province_region => String.t(),
          optional(:postal_code) => String.t(),
          :country => String.t()
        }

  @type controller_passport :: %{
          optional(:number) => String.t(),
          optional(:country) => String.t()
        }

  @type controller :: %{
          :first_name => String.t(),
          :last_name => String.t(),
          :title => String.t(),
          :date_of_birth => String.t(),
          :address => controller_address,
          optional(:passport) => controller_passport
        }

  @type error :: {:error, {integer, String.t()}} | {:error, any()}

  @type create_response :: {:ok, String.t()} | error

  @type response :: {:ok, map()} | error

  alias ExDwolla.Core
  alias ExDwolla.Utils

  @type get_all_request :: %{
          search: String.t(),
          status: String.t(),
          limit: integer,
          offset: integer
        }

  @spec get_all(get_all_request()) :: response()
  def get_all(%{} = params \\ %{}) do
    query_string = Utils.map_to_query_string(params)

    url =
      case query_string do
        "" -> "/customers"
        _ -> "/customers?#{query_string}"
      end

    Core.get_request(url)
  end

  @spec get(id()) :: response()
  def get(customer_id), do: Core.get_request("/customers/#{customer_id}")

  @type create_request :: %{
          :first_name => String.t(),
          :last_name => String.t(),
          :email => String.t(),
          :type => String.t(),
          :address1 => String.t(),
          optional(:address2) => String.t(),
          :city => String.t(),
          :state => String.t(),
          :postal_code => String.t(),
          optional(:date_of_birth) => String.t(),
          optional(:ssn) => String.t(),
          optional(:phone) => String.t(),
          optional(:business_name) => String.t(),
          optional(:ip_address) => String.t(),
          optional(:correlation_id) => String.t(),
          optional(:doing_business_as) => String.t(),
          optional(:business_type) => String.t(),
          optional(:business_classifiation) => String.t(),
          optional(:ein) => String.t(),
          optional(:website) => String.t(),
          optional(:controller) => controller
        }

  @doc """
  Create a new Customer

  ## Example
      iex> customer = %{
      ...>   first_name: "Earnnest",
      ...>   last_name: "Developer",
      ...> }
      iex> ExDwolla.Customers.create(customer)
      {:ok, "new_customer_id"}
  """
  @doc since: "0.0.1"
  @spec create(create_request()) :: create_response()
  def create(%{} = customer),
    do: Core.create_request("/customers", customer)

  @type update_request :: %{
          :first_name => String.t(),
          :last_name => String.t(),
          :email => String.t(),
          :type => String.t(),
          :address1 => String.t(),
          optional(:address2) => String.t(),
          :city => String.t(),
          :state => String.t(),
          :postal_code => String.t(),
          optional(:date_of_birth) => String.t(),
          optional(:ssn) => String.t(),
          optional(:phone) => String.t(),
          optional(:business_name) => String.t(),
          optional(:ip_address) => String.t(),
          optional(:correlation_id) => String.t(),
          optional(:doing_business_as) => String.t(),
          optional(:business_type) => String.t(),
          optional(:business_classifiation) => String.t(),
          optional(:ein) => String.t(),
          optional(:website) => String.t(),
          optional(:controller) => controller,
          :status => String.t()
        }

  @doc since: "0.0.1"
  @spec update(update_request(), id()) :: response()
  def update(%{} = customer, customer_id),
    do: Core.update_request("/customers/#{customer_id}", customer)

  @type create_funding_source_request :: %{
          optional(:plaid_token) => String.t(),
          :name => String.t(),
          :routing_number => String.t(),
          :account_number => String.t(),
          :bank_account_type => String.t()
        }

  @doc since: "0.0.1"
  @spec create_funding_source(create_funding_source_request(), id()) :: create_response()
  def create_funding_source(%{} = funding_source, customer_id),
    do: Core.create_request("/customers/#{customer_id}/funding-sources", funding_source)

  @doc since: "0.0.1"
  @spec create_iav_token(id()) :: response()
  def create_iav_token(customer_id),
    do: Core.update_request("/customers/#{customer_id}/iav-token", "")

  @doc since: "0.0.1"
  @spec create_funding_source_token(id()) :: create_response()
  def create_funding_source_token(customer_id),
    do: Core.update_request("/customers/#{customer_id}/funding-sources-token", "")

  @type upload_document_request :: %{
          customer_id: String.t(),
          filename: String.t(),
          path_or_binary: binary(),
          document_type: String.t()
        }

  @doc since: "0.0.1"
  @spec upload_document(upload_document_request()) :: response()
  def upload_document(%{
        customer_id: customer_id,
        filename: filename,
        path_or_binary: path_or_binary,
        document_type: document_type
      }),
      do:
        Core.upload_document_request("/customers/#{customer_id}/documents", filename, path_or_binary, %{
          documentType: document_type
        })
end

defmodule ExDwolla.FundingSources do
  @moduledoc """
  Funding Source related Dwolla API Functionality
  """
  @moduledoc since: "0.0.1"

  @type id() :: String.t()

  @type error :: {:error, {integer, String.t()}} | {:error, any()}

  @type response :: {:ok, map()} | error

  alias ExDwolla.Core

  @spec get(id()) :: response()
  def get(funding_source_id), do: Core.get_request("/funding-sources/#{funding_source_id}")

  @spec remove(id()) :: response()
  def remove(funding_source_id),
    do: Core.update_request("/funding-sources/#{funding_source_id}", %{removed: true})

  @spec send_microdeposits(id()) :: response()
  def send_microdeposits(funding_source_id),
    do: Core.update_request("/funding-sources/#{funding_source_id}/micro-deposits", "")

  @spec get_microdeposits(id()) :: response()
  def get_microdeposits(funding_source_id),
    do: Core.get_request("/funding-sources/#{funding_source_id}/micro-deposits")

  @spec verify_microdeposits(id(), Map.t()) :: response()
  def verify_microdeposits(funding_source_id, amounts),
    do: Core.update_request("/funding-sources/#{funding_source_id}/micro-deposits", amounts)
end

defmodule ExDwolla.Transfers do
  @moduledoc """
  Transfer related Dwolla API Functionality
  """
  @moduledoc since: "0.0.1"

  @type id() :: String.t()

  @type error :: {:error, {integer, String.t()}} | {:error, any()}

  @type create_response :: {:ok, String.t()} | error

  @type response :: {:ok, map()} | error

  alias ExDwolla.Core

  @spec get(id()) :: response()
  def get(transfer_id), do: Core.get_request("/transfers/#{transfer_id}")

  @type create_transfer_request :: %{
          :_links => map,
          :amount => map,
          optional(:metadata) => map,
          optional(:fees) => list,
          optional(:clearing) => map,
          optional(:ach_details) => map,
          optional(:correlation_id) => String.t()
        }

  @spec create(create_transfer_request(), String.t()) :: create_response()
  def create(%{} = transfer, idempotency_key),
    do: Core.update_request("/transfers", transfer, [{"Idempotency-Key", idempotency_key}])

  def simulate(),
    do: Core.update_request("/sandbox-simulations", "")
end

defmodule ExDwolla.WebhookSubscriptions do
  @moduledoc """
  Webhook related Dwolla API Functionality
  """
  @moduledoc since: "0.0.1"

  @type id() :: String.t()

  @type error :: {:error, {integer, String.t()}} | {:error, any()}

  @type create_response :: {:ok, String.t()} | error

  alias ExDwolla.Core

  @type create_webhook_request :: %{
          url: String.t(),
          secret: String.t()
        }

  @spec create(create_webhook_request()) :: create_response()
  def create(%{} = webhook_subscription),
    do: Core.create_request("/webhook-subscriptions", webhook_subscription)

  @spec delete(id()) :: {:ok} | error
  def delete(webhook_subscription_id),
    do: Core.delete_request("/webhook-subscriptions/#{webhook_subscription_id}")
end
