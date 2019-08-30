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

defmodule ExDwolla.Requests.GetCustomers do
  @moduledoc false
  defstruct [:limit, :offset, :search, :status]
end

defmodule ExDwolla.Requests.UploadDocument do
  @moduledoc false
  defstruct [:customer_id, :document_type, :filename, :file_contents]
end