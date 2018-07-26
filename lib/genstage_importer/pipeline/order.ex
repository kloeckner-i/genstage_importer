defmodule GenstageImporter.Pipeline.Order do
  @moduledoc """
  Order preprocessing pipeline
  """
  alias GenstageImporter.{ETS, Parser}

  def import() do
    products = :ets.new(:parts_order_status, [])
    pid = self()

    try do
      orders_path()
      |> File.stream!(read_ahead: 100_000)
      |> CSV.decode!(separator: ?|, headers: true)
      |> Flow.from_enumerable()
      |> Flow.filter(&valid/1)
      |> Flow.map(fn row ->
        %{
          order_number: row["ORDER_NUMBER"],
          product_number: row["PRODUCT_NUMBER"],
          ordered_pieces: Parser.parse_integer(row["ORDERED_PIECES"]),
          shipped_pieces: Parser.parse_integer(row["SHIPPED_PIECES"]),
          pending: pending(row)
        }
      end)
      |> Flow.partition(key: {:key, :order_number}, stages: 4)
      |> Flow.reduce(fn -> :ets.new(:orders, []) end, fn row, table ->
        order_number = row[:order_number]

        {_, _, shipped_pieces, pending} = ETS.fetch_order(table, order_number)

        ETS.insert_order(
          table,
          order_number,
          row[:product_number],
          row[:ordered_pieces],
          shipped_pieces + row[:shipped_pieces],
          pending || row[:pending]
        )
      end)
      |> Flow.on_trigger(fn ets ->
        :ets.give_away(ets, pid, [])
        {[ets], ets}
      end)
      |> Enum.to_list()
      |> Enum.each(fn table ->
        ETS.each_order(
          table,
          fn {_, product_number, ordered_pieces, shipped_pieces, pending}, _ ->
            {current_pending, current_pending_pieces, _} =
              ETS.fetch_product(products, product_number)

            ETS.insert_product(
              products,
              product_number,
              current_pending || pending,
              calculate_pending_pieces(
                current_pending_pieces,
                ordered_pieces - shipped_pieces,
                pending
              )
            )
          end
        )

        :ets.delete(table)
      end)

      products
    rescue
      ex ->
        :ets.delete(products)
        reraise(ex, System.stacktrace())
    end
  end

  defp calculate_pending_pieces(current_val, diff, true), do: current_val + diff
  defp calculate_pending_pieces(current_val, diff, false), do: current_val

  defp valid(row) do
    row["LINE_STATUS"] != "Closed" || row["BILL_OF_LADING"] != ""
  end

  defp pending(row) do
    row["LINE_STATUS"] == "Open" && row["BILL_OF_LADING"] == ""
  end

  defp orders_path,
    do: "./files/orders.csv"
end
