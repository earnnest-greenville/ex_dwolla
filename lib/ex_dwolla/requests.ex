defmodule ExDwolla.Requests.CreateFundingSource do
  @moduledoc false
  defstruct [:routing_number, :account_number, :bank_account_type, :name, :channels]
end

defmodule ExDwolla.Requests.GetTransfersForAccount do
  @moduledoc false
  defstruct [
    :search,
    :start_amount,
    :end_amount,
    :start_date,
    :end_date,
    :status,
    :correlation_id,
    :limit,
    :offset
  ]
end

defmodule ExDwolla.Requests.Customer.Create do
  @moduledoc false
  defstruct [
    :first_name,
    :last_name,
    :email,
    :type,
    :address1,
    :address2,
    :city,
    :state,
    :postal_code,
    :date_of_birth,
    :ssn,
    :phone,
    :business_name,
    :ip_address,
    :correlation_id,
    :doing_business_as,
    :business_type,
    :business_classification,
    :ein,
    :website,
    :controller
  ]
end

defmodule ExDwolla.Requests.Customer.Update do
  @moduledoc false
  defstruct [
    :first_name,
    :last_name,
    :email,
    :type,
    :address1,
    :address2,
    :city,
    :state,
    :postal_code,
    :date_of_birth,
    :ssn,
    :phone,
    :business_name,
    :ip_address,
    :correlation_id,
    :doing_business_as,
    :business_type,
    :business_classification,
    :ein,
    :website,
    :controller,
    :status
  ]
end

defmodule ExDwolla.Requests.Customer.CreateFundingSource do
  @moduledoc false
  defstruct [
    :plaid_token,
    :name,
    :routing_number,
    :account_number,
    :bank_account_type
  ]
end

defmodule ExDwolla.Requests.Customer.Controller do
  @moduledoc false
  defstruct [
    :first_name,
    :last_name,
    :title,
    :date_of_birth,
    :ssn,
    :address,
    :passport
  ]
end

defmodule ExDwolla.Requests.Customer.Controller.Address do
  @moduledoc false
  defstruct [
    :address1,
    :address2,
    :address3,
    :city,
    :state_province_region,
    :postal_code,
    :country
  ]
end

defmodule ExDwolla.Requests.Customer.Controller.Passport do
  @moduledoc false
  defstruct [
    :number,
    :country
  ]
end

defmodule ExDwolla.Requests.GetCustomers do
  @moduledoc false
  defstruct [:limit, :offset, :search, :status]
end

defmodule ExDwolla.Requests.UploadDocument do
  @moduledoc false
  defstruct [:customer_id, :beneficial_owner_id, :document_type, :filename, :path]
end

defmodule ExDwolla.Requests.Transfers.Create do
  @moduledoc false
  defstruct [:_links, :amount, :metadata, :fees, :clearing, :ach_details, :correlation_id, :clearing]
end

defmodule ExDwolla.Requests.WebhookSubscriptions.Create do
  @moduledoc false
  defstruct [:url, :secret]
end