defmodule GenstageImporter.ETS do
  @moduledoc """
  Some wrappers around ETS tables
  """

  def each_order(table, fun) do
    :ets.foldl(fun, %{}, table)
  end

  def fetch_order(table, order_number) do
    if :ets.member(table, order_number) do
      [{_key, el1, el2, el3, el4}] = :ets.lookup(table, order_number)
      {el1, el2, el3, el4}
    else
      {nil, 0, 0, false}
    end
  end

  def fetch_product(table, product_number) do
    if :ets.member(table, product_number) do
      [{_key, el2, el3}] = :ets.lookup(table, product_number)
      {el2, el3, true}
    else
      {false, 0, false}
    end
  end

  def insert_order(table, order_number, product_number, ordered_pieces, shipped_pieces, pending) do
    :ets.insert(
      table,
      {order_number, product_number, ordered_pieces, shipped_pieces, pending}
    )

    table
  end

  def insert_product(table, product_number, pending, pending_pieces) do
    :ets.insert(table, {product_number, pending, pending_pieces})
  end
end
