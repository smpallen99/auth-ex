defmodule AuthEx.Ability do
  import AuthEx.Utils, only: [escape: 1]
  #use Ecto.Query
  #import Ecto.Query

  defmacro __using__(_opts \\ []) do
    quote do
      import AuthEx.Ability
      import AuthEx.Plugs
      require Ecto.Query
      import Ecto.Query
      # Module.register_attribute __MODULE__, :abilities, accumulate: true, persist: true
    end
  end

  defmacro can(actions, module, opts \\ []) do
    quote do
      actions = AuthEx.Utils.actions unquote(actions)
      item = %{can: true, actions: actions, module: unquote(module), opts: unquote(opts)}
      var!(ability_blocks, AuthEx.Ability) = [item | var!(ability_blocks, AuthEx.Ability)]

    end
  end

  defmacro abilities(resource, [do: block]) do
    contents = quote do
      unquote(block)
    end

    quote location: :keep, bind_quoted: [resource: escape(resource), contents: escape(contents)] do
      #def handle_ability(var!(conn), unquote(resource) = var!(resource), action) do
      def authorized?(unquote(resource) = var!(resource), action, model) do
      #def handle_ability(action, model) do 
        model_name = model.__struct__
        res = var!(resource)
        var!(ability_blocks, AuthEx.Ability) = []
        unquote(contents)
        ability_blocks = Enum.reverse var!(ability_blocks, AuthEx.Ability)
        Enum.reduce ability_blocks, false, fn(item, acc) -> 
          if valid_action? res, item, action, model do
            true
          else
            acc 
          end
        end
      end
      def valid_action?(resource, %{actions: actions, module: model_name, opts: []}, action, 
          %{__struct__: model_name} = model) do
        action in actions
      end
      def valid_action?(resource, %{actions: actions, module: model_name, opts: opts}, action, 
          %{__struct__: model_name} = model) do
        if action in actions do
          valid_opts? model, opts, false
        else
          false
        end
      end
      def valid_action?(_, _, _, _), do: false

      def valid_opts?(model, [], acc), do: acc
      def valid_opts?(model, [{field, list} | t], acc) when is_list(list) do
        new_acc = if Map.get(model, field) in list, do: true, else: acc
        valid_opts?(model, t, new_acc)
      end
      def valid_opts?(model, [{field, value} | t], acc) do
        new_acc = if Map.get(model, field) == value, do: true, else: acc
        valid_opts?(model, t, new_acc)
      end


      def load_resource(unquote(resource) = var!(resource), action, model) do
        model_name = model.__struct__
        res = var!(resource)
        var!(ability_blocks, AuthEx.Ability) = []
        unquote(contents)
        ability_blocks = Enum.reverse var!(ability_blocks, AuthEx.Ability)
        query = from r in model_name
        IO.puts "---------------------------------"
        IO.inspect ability_blocks
        IO.puts "================================="

        something = Enum.reduce(ability_blocks, [], 
          fn(item, acc) ->
            IO.puts "ability blocks: item: #{inspect item}"
            #if valid_action? res, item, action, model do
              # build_query(res, 0, item[:opts], action, model, acc)
              #AuthEx.Builder.build_query(res, 0, item[:opts], action, model, query)
            # else
            #   acc
            # end
          end)
        # |> Enum.reduce(query, fn(item, query) -> 
        #   case item do
        #     nil -> query
        #     {:where, name, value} -> 
        #       where(query, [q], field(q, ^name) == ^value)
        #     {:preload, [pl]} -> 
        #       preload(query, ^pl)
        #     {:preload, pl} -> 
        #       preload(query, [^pl])
        #     {:join, name, %Ecto.Association.HasThrough{} = has_through, %{} = fields} ->
        #       # assume singular field
        #       {f_name, value} = Map.to_list(fields) |> hd
        #       %{assoc: assoc1, assoc_key: assoc_key1, owner_key: owner_key1} =  
        #         has_through.owner.__schema__(:association, hd has_through.through)
        #       %{assoc: assoc2, assoc_key: assoc_key2, owner_key: owner_key2} = assoc1
        #       query
        #       |> join(:inner, [j0], j1 in ^assoc1, field(j1, ^assoc_key1) == field(j0, ^owner_key1))
        #       |> join(:inner, [_, j1], j2 in ^assoc2, field(j1, ^owner_key2) == field(j2, ^assoc_key2))
        #       |> where([_, _, j0], field(j0, ^f_name) in ^value)
        #   end
        # end)
        #IO.puts "something: #{inspect something}"
        something
      end

      # can :index, Test.Item, preload: [user: [:roles]], user: %{roles: %{name: ~w(admin superadmin)}}

      # User |> join(:inner, [u], ur in UserRole, ur.user_id == u.id) 
      # |> join(:inner, [u, ur], r in Role, ur.role_id == r.id and r.name in ~w(admin superadmin)) 

       # SalesOrder 
       # |> join(:inner, [s], j in User, s.user_id == j.id) 
       # |> join(:inner, [_, j1], j2 in UserRole, j2.user_id == j1.id) 
       # |> join(:inner, [_, _, j0], j1 in Role, j0.role_id == j1.id) 
       # |> where([_, _, _, j0], j0.name == ^role)

      # def build_query(resource, item, action, %{__struct__: model_name} = model) when action in [:edit, :show] do
      #   %{can: can, actions: actions, module: module, opts: opts} = item
      #   query = for a in model_name, where: a.id == ^id, preload: [....]
      #   Repo.one! query
      # end
      # def build_query(resource, item, :destroy, %{__struct__: model_name} = model) do
      #   Repo.get |> Repo.delete
      # end
      # def build_query(resource, item, :new, %{__struct__: model_name} = model) do
      #   %model_name{}
      # end
      # def build_query(resource, item, :create, %{__struct__: model_name} = model) do
      #   # create the resource
      #   Repo.insert ...
      # end
      # def build_query(resource, item, :update, %{__struct__: model_name} = model) do
      #   # run changeset
      #   Repo.update
      # end
    end
  end

end
