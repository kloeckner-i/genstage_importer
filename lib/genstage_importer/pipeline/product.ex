defmodule GenstageImporter.Pipeline.Product do
  @moduledoc """
  Part import pipeline
  """

  alias GenstageImporter.EctoImporter
  alias GenstageImporter.Parser
  alias GenstageImporter.Product
  alias GenstageImporter.Pipeline.Order

  def import do
    # table_ref = Shipment.import(shipment_path())

    try do
      products_path()
      |> File.stream!()
      |> CSV.decode!(separator: ?|, headers: true)
      |> Flow.from_enumerable()

      # |> Flow.partition()
      # |> Flow.map(&transform(&1, "table_ref"))
      # |> EctoImporter.import(Product)
    after
      # :ets.delete(table_ref)
    end
  end

  # defp transform(row, table_ref) do
  #   import_id = import_id(row)

  #   inventory = InventoryStore.lookup(table_ref, import_id)

  #   price = Parser.parse_decimal(row["PART_PRICE"])

  #   %{
  #     external_id: row["PRODUCT_NUMBER"],
  #     product_number: row["PRODUCT_NUMBER"],
  #     description: part_description(row),
  #     commodity: row["COMMODITY_DESC"],
  #     price: price,
  #     approx_weight: Parser.parse_float(row["PART_THEO_WEIGHT"]),
  #     blanket_po_number: row["BLANKET_PO"],
  #     priced_at: row["PRICED_AT"],
  #     price_inventory: inventory.price_inventory,
  #     pieces_on_floor: inventory.pieces_on_floor,
  #     pieces_on_floor_unit: inventory.pieces_on_floor_unit |> String.downcase(),
  #     weight_on_floor: inventory.weight_on_floor,
  #     weight_on_floor_unit: inventory.weight_on_floor_unit |> String.downcase(),
  #     quantity_shipped: inventory.quantity_shipped,
  #     weight_shipped: inventory.weight_shipped,
  #     price_per:
  #       Pricing.price_per(
  #         row["PRICED_AT"],
  #         price,
  #         Decimal.div(inventory.sum_price, total_on_floor(inventory))
  #       ),
  #     price_per_unit: row["PRICE_UOM"],
  #     total_on_floor: total_on_floor(inventory)
  #   }
  #   |> merge_price_intervals(import_id)
  # end

  defp products_path,
    do: "./files/products.csv"
end
