defmodule AuthEx.Builder do
  @debug false

  # import AuthEx.Utils, only: [debug: 1]
  require Ecto.Query
  import Ecto.Query
  require Logger

  def build_query(opts, action, %{__struct__: model_name}, level, acc, conn) do
    debug "9. build_query params: #{inspect conn.params}"
    build_query(opts, action, model_name, level, acc, conn)
  end
  def build_query(%{} = opts, action, model_name, level, acc, conn) do
    debug "8. build_query params: #{inspect conn.params}"
    Map.to_list(opts) |> build_query(action, model_name, level, acc, conn)
  end
  def build_query([{:preload, [preload]} | t], action, model_name, level, acc, conn) do
    debug "0. build_query preload action: #{action}, #{inspect preload}"
    debug "acc: #{inspect acc}"
    q = preload(acc, ^preload)
    build_query(t, action, model_name, level, q, conn)
  end
  def build_query([{:preload, preload} | t], action, model_name, level, acc, conn) do
    debug "0.0. build_query preload action: #{action}, #{inspect preload}"
    debug "acc: #{inspect acc}"
    q = preload(acc, ^preload)
    build_query(t, action, model_name, level, q, conn)
  end

  def build_query([{name, value} | t], :index, model_name, level, acc, conn) do
    debug "1. build_query level: #{level}, action: :index, model_name: #{model_name}, name: #{name}, value: #{inspect value}"
    query = cond do 
      name in model_name.__schema__(:fields) -> 
        build_where(acc, name, value, level)
      name in model_name.__schema__(:associations) -> 
        build_association(acc, name, value, :index, model_name, level, conn)

      true -> 
        Logger.error "Unknown field type level: #{level}, model_name: #{model_name}, name: #{name}"
        throw {:error, "Unknown field type", model_name, name}
    end
    build_query(t, :index, model_name, level, query, conn)
  end
  def build_query([], action, _, level, query, conn) when action in [:show, :edit] do 
    id = conn.params["id"]
    debug "4.0 build_query action: #{inspect action}, id: #{id}"
    where(query, [q: level], q.id == ^id)
  end
  def build_query([], action, _, level, query, conn) when action in [:update] do 
    id = conn.params["id"]
    debug "4.2 build_query action: #{inspect action}, id: #{id}"
    where(query, [q: level], q.id == ^id)
  end
  def build_query([], action, _, _, acc, conn) do 
    debug "4.5 build_query action: #{inspect action}"
    build_order_by(acc, action, conn)
  end
  def build_query(item, :index, _, level, acc, _conn) do
    debug "build query default action: :index, level: #{level}, item: #{inspect item}"
    acc
  end
  def build_query([item | t], action, model_name, level, acc, conn) do
    id = conn.params["id"]
    debug "6. build_query action: #{inspect action}, model_name: #{model_name}, id: #{id}, acc: #{inspect acc}"
    build_query(t, action, model_name, level, where(acc, [q: level], q.id == ^id), conn)
  end

  def build_order_by(query, action, conn) do
    debug "build_order_by: #{action}, #{inspect query}, params: #{inspect conn.params}"
    query
  end
  def build_where(query, name, value, level) when is_list(value) do
    debug "build_where: name: #{name}, value: #{inspect value}"
    where(query, [q: level], field(q, ^name) in ^value)
  end
  def build_where(query, name, value, level) do
    debug "build_where: name: #{name}, value: #{inspect value}"
    where(query, [q: level], field(q, ^name) == ^value)
  end

  def build_association(query, name, value, action, model_name, level, conn) do
    res = case model_name.__schema__(:association, name) do
      %Ecto.Association.BelongsTo{} = association -> 
        %{assoc: assoc, assoc_key: assoc_key, owner_key: owner_key} = association
        q = join(query, :inner, [j: level], j1 in ^assoc, field(j, ^owner_key) == field(j1, ^assoc_key))
        debug "belongs_to: level: #{level}, #{inspect association}"
        build_query(value, action, assoc, level + 1, q, conn)
      %Ecto.Association.HasThrough{
           cardinality: :many, field: field, owner: owner, owner_key: owner_key, 
           through: through} = association -> 
        [join_model, field] = through
        debug "has_through: level: #{level}, #{inspect owner.__schema__(:association, join_model)}"
        %{assoc: assoc1, owner_key: owner_key1, assoc_key: assoc_key1} = owner.__schema__(:association, join_model)
        debug "assoc field: #{inspect assoc1.__schema__(:association, field)}"
        %{assoc: model_name2, assoc_key: assoc_key2, owner_key: owner_key2} = assoc1.__schema__(:association, field)
        q = join(query, :inner, [j: level], j1 in ^assoc1, field(j, ^owner_key1) == field(j1, ^assoc_key1))
        |> join(:inner, [j: level + 1], j2 in ^model_name2, field(j, ^owner_key2) == field(j2, ^assoc_key2))

        build_query(value, action, model_name2, level + 2, q, conn)
      other -> 
        Logger.error "xxxx other: #{inspect other}"
        query
    end
    res
  end
  
  defp debug(message) do
    if @debug do
      IO.puts "ExAuth Debug: " <> message
    end
  end
end
