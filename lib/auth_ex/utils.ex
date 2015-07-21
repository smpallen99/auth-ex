defmodule AuthEx.Utils do

  @action_list [:index, :show, :create, :update, :new, :edit, :destroy]
  @actions [
    manage: @action_list,
    read: [:index, :show],
    write: [:create, :update, :new, :edit, :destroy],
  ]

  def actions(action) when is_atom(action) and action in @action_list, do: [action]
  def actions(action) when is_atom(action) do
   Keyword.get(@actions, action, nil)
  end
  def actions(actions) when is_list(actions), do: Enum.map(actions, &AuthEx.Utils.actions/1)
  
  def escape(var) do
    Macro.escape(var, unquote: true)
  end

  def current_user(conn, opts \\ []) do
    current_user_name = opts[:current_user] || Application.get_env(:auth_ex, :current_user, :current_user)
    Dict.fetch! conn.assigns, current_user_name
  end
end
