defmodule GenstageImporter.EctoImporter do
  @moduledoc """
  Contains functions that import input stream to specified ecto schema.
  Also handles deletes of items that are no longer in CSV files.
  """
  alias GenstageImporter.Repo
  alias Flow.Window, as: FlowWindow
  import Ecto.Query, only: [from: 2]

  def import(input_flow, schema) do
    input_flow
    |> split_in_batches()
    |> upsert(schema)
    |> delete(schema)
  end

  defp split_in_batches(input_flow) do
    input_flow
    |> Flow.partition(window: FlowWindow.count(1_000), stages: 4)
    |> Flow.reduce(fn -> [] end, fn item, batch ->
      [item | batch]
    end)
  end

  defp upsert(input_flow, schema) do
    input_flow
    |> Flow.map_state(fn items ->
      Repo.insert_all(
        schema,
        add_timestamps(items),
        on_conflict: :replace_all,
        conflict_target: :external_id
      )

      Enum.map(items, & &1.external_id)
    end)
    |> Flow.emit(:state)
    |> Enum.to_list()
    |> Enum.reduce(&++/2)
    |> MapSet.new()
  end

  defp delete(imported_ids, schema) do
    query = from(p in schema, select: p.external_id)

    existing_ids = query |> Repo.all() |> MapSet.new()

    ids_to_delete = existing_ids |> MapSet.difference(imported_ids) |> MapSet.to_list()

    ids_to_delete
    |> Enum.chunk_every(1_000)
    |> Enum.map(fn ids ->
      delete_query =
        from(
          p in schema,
          where: p.external_id in ^ids
        )

      Repo.delete_all(delete_query)
    end)
  end

  defp add_timestamps(items) do
    items
    |> Enum.map(fn item ->
      item
      |> Map.put(:inserted_at, DateTime.utc_now())
      |> Map.put(:updated_at, DateTime.utc_now())
    end)
  end
end
