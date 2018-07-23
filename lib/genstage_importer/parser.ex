defmodule GenstageImporter.Parser do
  @moduledoc """
  Contains functions to parse some raw data from CSV files
  """

  require Logger

  def parse_decimal(decimal_string) do
    case Decimal.parse(decimal_string) do
      :error ->
        Logger.debug(fn ->
          "[GenstageImporter] bad decimal value: [#{decimal_string}]"
        end)

        Decimal.new(0)

      {:ok, decimal} ->
        decimal
    end
  end

  def parse_integer(integer_string) do
    case Integer.parse(integer_string) do
      :error ->
        Logger.debug(fn ->
          "[GenstageImporter] bad integer value: [#{integer_string}]"
        end)

        0

      {integer, _} ->
        integer
    end
  end
end
