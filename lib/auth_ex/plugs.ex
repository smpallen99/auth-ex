defmodule AuthEx.Plugs do

  def authorize_resource(conn, opts) do
    conn
    |> action_valid?(opts)
    |> case do
      true  -> _authorize_resource(conn, opts)
      false -> conn
    end
  end
  
  defp _authorize_resource(conn, opts) do
    current_user_name = opts[:current_user] || Application.get_env(:canary, :current_user, :current_user)
    current_user = Dict.fetch! conn.assigns, current_user_name
    action = get_action(conn)

    resource = cond do
      action in [:index, :new, :create] ->
        opts[:model]
      true      ->
        fetch_resource(conn, opts)
    end

    case current_user |> Test.Ability.authorized? action, resource do
      true  ->
        %{ conn | assigns: Map.put(conn.assigns, :authorized, true) }
      false ->
        %{ conn | assigns: Map.put(conn.assigns, :authorized, false) }
    end
  end

  defp get_action(conn) do
    conn.assigns
    |> Map.fetch(:action)
    |> case do
      {:ok, action} -> action
      _             -> conn.private.phoenix_action
    end
  end

  defp action_valid?(conn, opts) do
    conn
  end

  defp fetch_resource(conn, opts) do

  end
end
