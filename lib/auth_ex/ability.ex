defmodule AuthEx.Ability do
  import AuthEx.Utils, only: [escape: 1]
  require Logger
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
      require Logger
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
      def valid_action?(_resource, %{actions: actions, module: model_name}, action, model_name) 
          when is_atom(model_name) do
        res = action in actions
        Logger.info "1. valid_action? #{action}, #{res}"
        res
      end
      def valid_action?(resource, %{actions: actions, module: model_name, opts: []}, action, 
          %{__struct__: model_name} = model) do
        res = action in actions
        Logger.info "2. valid_action? #{action} #{res}"
        res
      end
      def valid_action?(resource, %{actions: actions, module: model_name, opts: opts}, action, 
          %{__struct__: model_name} = model) do
        res = if action in actions do
          valid_opts? model, opts, false
        else
          false
        end
        Logger.info "3. valid_action? #{action} #{res}"
        res
      end
      def valid_action?(_, _, _, _) do 
        Logger.info "4. valid_action? false"
        false
      end

      def valid_opts?(model, [], acc) do 
        Logger.info "0. valid_opts? #{acc}"
        acc
      end
      def valid_opts?(model, [{field, list} | t], acc) when is_list(list) do
        Logger.info "1. valid_opts? model_name: #{model.__struct__}, field: #{field}, list: #{inspect list}"
        new_acc = if Map.get(model, field) in list, do: true, else: acc
        valid_opts?(model, t, new_acc)
      end
      def valid_opts?(model, [{field, value} | t], acc) do
        Logger.info "2. valid_opts? model_name: #{model.__struct__}, field: #{field}, value: #{inspect value}"
        new_acc = if Map.get(model, field) == value, do: true, else: acc
        valid_opts?(model, t, new_acc)
      end


      def load_resource(unquote(resource) = var!(resource), action, model) do
        model = if is_atom(model), do: model.__struct__, else: model
        model_name = model.__struct__
        res = var!(resource)
        var!(ability_blocks, AuthEx.Ability) = []
        unquote(contents)
        ability_blocks = Enum.reverse var!(ability_blocks, AuthEx.Ability)
        #query = from r in model_name
        # IO.puts "---------------------------------"
        # IO.inspect ability_blocks
        # IO.puts "================================="
        Logger.info "====> model_name: #{model_name}"
        Enum.reduce(ability_blocks, model_name, 
          fn(item, acc) ->
            Logger.debug "==> ability blocks: item: #{inspect item}"
            if valid_action? res, item, action, model do
              AuthEx.Builder.build_query(item[:opts], action, model_name, 0, acc)
             else
               acc
             end
          end)
        |> get_resource(Application.get_env(:auth_ex, :repo), action)
      end

      defp get_resource(query, repo, :index), do: repo.all(query)
      defp get_resource(query, repo, _), do: repo.one!(query)

    end

  end

end
