defmodule GenstageImporter.Product do
  @moduledoc """
  Products schema
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "products" do
    # fields from products.csv file
    field(:product_number, :string)
    field(:external_id, :string)
    field(:description, :string)
    field(:commodity, :string)
    field(:price, :decimal)

    # precomputed fields from orders.csv

    # true if at least one order is present for the product
    field(:orders_present, :boolean)
    # true if at least one pending order is present
    field(:pending_orders_present, :boolean)
    # sum of pending (left to ship) pieces over all orders for the product
    field(:pending_pieces, :integer)

    timestamps()
  end

  @doc false
  def changeset(%Product{} = product, attrs) do
    product
    |> cast(attrs, [
      :product_number,
      :external_id,
      :description,
      :commodity,
      :price,
      :orders_present,
      :pending_orders_present,
      :pending_pieces
    ])
    |> unique_constraint(:import_id)
  end
end
