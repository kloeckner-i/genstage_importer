defmodule GenstageImporter.Product do
  @moduledoc """
  Products schema
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "products" do
    field(:product_number, :string)
    field(:external_id, :string)
    field(:description, :string)
    field(:commodity, :string)
    field(:price, :decimal)

    field(:orders_present, :boolean)
    field(:pending_orders_present, :boolean)
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
