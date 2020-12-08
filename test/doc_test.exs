defmodule DocTest do
  use ExUnit.Case
  doctest ExDwolla
  doctest ExDwolla.Accounts
  doctest ExDwolla.Customers
  doctest ExDwolla.Utils
end
