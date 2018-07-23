defmodule GenstageImporter.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add(:product_number, :string)
      add(:external_id, :string)
      add(:description, :string)
      add(:price, :decimal)
      add(:commodity, :string)

      add(:orders_present, :boolean)
      add(:pending_orders_present, :boolean)
      add(:pending_pieces, :integer)

      timestamps()
    end

    create(unique_index(:products, [:external_id]))
  end
end
