defmodule GenstageImporter.Pipeline.Product do
  @moduledoc """
  Product import pipeline
  """

  require Logger

  alias GenstageImporter.EctoImporter
  alias GenstageImporter.ETS
  alias GenstageImporter.Parser
  alias GenstageImporter.Product
  alias GenstageImporter.Pipeline.Order

  def import do
    time_in_millis = :os.system_time(:millisecond)
    # preprocess orders, get a reference to ETS table
    table_ref = Order.import()
    Logger.info("Preprocessing done in #{:os.system_time(:millisecond) - time_in_millis}ms")

    try do
      time_in_millis = :os.system_time(:millisecond)

      # here the straightforward flow
      products_path()
      |> File.stream!(read_ahead: 100_000)
      |> CSV.decode!(separator: ?|, headers: true)
      |> Flow.from_enumerable()
      |> Flow.map(&transform(&1, table_ref))
      |> Flow.partition()
      |> EctoImporter.import(Product)

      Logger.info("Import done in #{:os.system_time(:millisecond) - time_in_millis}ms")
    after
      :ets.delete(table_ref)
    end
  end

  # merge CSV values with precomputed orders data
  defp transform(row, table_ref) do
    product_number = row["PRODUCT_NUMBER"]

    {pending, pending_pieces, orders_present} = ETS.fetch_product(table_ref, product_number)

    price = Parser.parse_decimal(row["PRICE"])

    %{
      external_id: product_number,
      product_number: product_number,
      description: row["SHORT_DESC"],
      price: price,
      commodity: row["COMMODITY"],
      pending_orders_present: pending,
      orders_present: orders_present,
      pending_pieces: pending_pieces
    }
  end

  defp products_path,
    do: "./files/products.csv"
end
