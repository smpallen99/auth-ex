defmodule AuthEx.Builder do
  require Ecto.Query
  import Ecto.Query

  def build_query(%{} = opts, action, %{__struct__: model_name} = model, level, acc) do
    Map.to_list(opts) |> build_query(action, model, level, acc)
  end
  def build_query([{:preload, preload} | t], action, %{__struct__: model_name} = model, level, acc) do
    IO.puts "Preload: #{inspect preload}"
    build_query(t, action, model, level, [{:preload, preload} | acc])
  end

  def build_query([{name, value} | t], :index, %{__struct__: model_name} = model, level, acc) do
    IO.puts "build_query map: model_name: #{model_name}, name: #{name}, value: #{inspect value}"
    query = cond do 
      name in model_name.__schema__(:fields) -> 
        build_where(acc, name, value)
      name in model_name.__schema__(:associations) -> 
        build_association(acc, name, value, model_name)

      true -> 
        throw {:error, "Unknown field type", model_name, name}
    end
    build_query t, :index, model, level, build_query(value, :index, model, level + 1, query)
  end
  def build_query([{name, value} | t], :index, %{__struct__: model_name} = model, level, acc) do
    IO.puts "build_query 2 name: #{name}" 
    build_query(t, :index, model, level, [{:where, name, value} | acc])
  end
  def build_query(item, :index, _, _, acc) do
    IO.puts "build query default item: #{inspect item}"
    acc
  end

  def build_where(query, name, value) do
    where(query, [q], field(q, ^name) == ^value)
  end

  def build_association(query, name, value, model_name) do
    res = case model_name.__schema__(:association, name) do
      %Ecto.Association.HasThrough{} = association -> 
        %{assoc: assoc1, assoc_key: assoc_key1, owner_key: owner_key1} = association
        association
      other -> 
        other
    end
    IO.puts "Association: #{inspect res}"
    query
  end
  
end
