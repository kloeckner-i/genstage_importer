defmodule GenstageImporter.Pipeline.Order do
  @moduledoc """
  Order preprocessing pipeline
  """
  alias GenstageImporter.Parser

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

        {shipped_pieces, pending} =
          if :ets.member(table, order_number) do
            [{_key, _el1, _el2, el3, el4}] = :ets.lookup(table, order_number)
            {el3, el4}
          else
            {0, false}
          end

        :ets.insert(
          table,
          {order_number, row[:product_number], row[:ordered_pieces],
           shipped_pieces + row[:shipped_pieces], pending || row[:pending]}
        )

        table
      end)
      |> Flow.map_state(fn ets ->
        :ets.give_away(ets, pid, [])
        ets
      end)
      |> Flow.emit(:state)
      |> Enum.to_list()
      |> Enum.each(fn table ->
        :ets.foldl(
          fn {_, product_number, ordered_pieces, shipped_pieces, pending}, _ ->
            {current_pending, current_pending_pieces} =
              if :ets.member(products, product_number) do
                [{_key, el2, el3}] = :ets.lookup(products, product_number)
                {el2, el3}
              else
                {false, 0}
              end

            new_pending_pieces =
              if pending do
                current_pending_pieces + (ordered_pieces - shipped_pieces)
              else
                current_pending_pieces
              end

            :ets.insert(
              products,
              {product_number, current_pending || pending, new_pending_pieces}
            )
          end,
          %{},
          table
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

  defp valid(row) do
    row["LINE_STATUS"] != "Closed" || row["BILL_OF_LADING"] != ""
  end

  defp pending(row) do
    row["LINE_STATUS"] == "Open" && row["BILL_OF_LADING"] == ""
  end

  defp orders_path,
    do: "./files/orders.csv"
end
