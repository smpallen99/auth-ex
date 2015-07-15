defmodule AuthEx.Ability do
  import AuthEx.Utils, only: [escape: 1]

  defmacro __using__(_opts \\ []) do
    quote do
      import AuthEx.Ability
      import AuthEx.Plugs
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
      def handle_ability(unquote(resource) = var!(resource), action, model) do
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
          {field, value} = hd opts
          Map.get(model, field) == value
        else
          false
        end
      end
      def valid_action?(_, _, _, _), do: false
    end
  end

end
