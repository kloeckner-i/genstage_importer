defmodule GenstageImporter.Pipeline.Order do
  @moduledoc """
  Order preprocessing pipeline
  """
  alias GenstageImporter.{ETS, Parser}

  def import() do
    # ETS table that stores the end result
    products = :ets.new(:products_order_status, [])
    # PID of the current process is needed for
    pid = self()

    try do
      orders_path()
      |> File.stream!(read_ahead: 100_000)
      |> CSV.decode!(separator: ?|, headers: true)
      # initial flow is created from file input stream
      |> Flow.from_enumerable()
      # we immediately filter out rows to be ignored
      |> Flow.filter(&valid/1)
      # as early as possible transform original map to a smaller one to save memory
      |> Flow.map(fn row ->
        %{
          order_number: row["ORDER_NUMBER"],
          product_number: row["PRODUCT_NUMBER"],
          ordered_pieces: Parser.parse_integer(row["ORDERED_PIECES"]),
          shipped_pieces: Parser.parse_integer(row["SHIPPED_PIECES"]),
          pending: pending(row)
        }
      end)
      # here input flow is partitioned and sent to 4 concurrent stages
      # also, we ensure that events with the same order_number go to the same stage
      |> Flow.partition(key: {:key, :order_number}, stages: 4)
      # this step reduces incoming event to an ETS table with aggregated information
      # about each order
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
      # after reduce process is done, next stage is triggered
      # here we give away ETS table ownership to the parent process, flow is done
      # at this stage
      |> Flow.on_trigger(fn ets ->
        :ets.give_away(ets, pid, [])
        {[ets], ets}
      end)
      # for each result, we iterate over orders table and calculate aggregated values for products
      |> Enum.to_list()
      |> Enum.each(fn table ->
        ETS.each_order(table, fn order_tuple, _ ->
          process_order(products, order_tuple)
        end)

        :ets.delete(table)
      end)

      products
    rescue
      ex ->
        :ets.delete(products)
        reraise(ex, System.stacktrace())
    end
  end

  defp process_order(table, {_, product_number, ordered_pieces, shipped_pieces, pending}) do
    {current_pending, current_pending_pieces, _} = ETS.fetch_product(table, product_number)

    ETS.insert_product(
      table,
      product_number,
      current_pending || pending,
      calculate_pending_pieces(
        current_pending_pieces,
        ordered_pieces - shipped_pieces,
        pending
      )
    )
  end

  defp calculate_pending_pieces(current_val, diff, true), do: current_val + diff
  defp calculate_pending_pieces(current_val, _, false), do: current_val

  defp valid(row) do
    row["LINE_STATUS"] != "Closed" || row["BILL_OF_LADING"] != ""
  end

  defp pending(row) do
    row["LINE_STATUS"] == "Open" && row["BILL_OF_LADING"] == ""
  end

  defp orders_path,
    do: "./files/orders.csv"
end
