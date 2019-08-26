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