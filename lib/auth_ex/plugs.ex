defmodule AuthEx.Plugs do
  import Keyword, only: [has_key?: 2]
  require Logger

  def load_resource(conn, opts) do
    conn
    |> action_valid?(opts)
    |> case do
      true  -> _load_resource(conn, opts)
      false -> conn
    end
  end

  defp _load_resource(conn, opts) do
    loaded_resource = case get_action(conn) do
      :index  ->
        fetch_all(conn, opts)
      :new    ->
        nil
      :create ->
        nil
      _       ->
        fetch_resource(conn, opts)
    end

    %{ conn | assigns: Map.put(conn.assigns, resource_name(conn, opts), loaded_resource) }
  end

  def authorize_resource(conn, opts) do
    conn
    |> action_valid?(opts)
    |> case do
      true  -> _authorize_resource(conn, opts)
      false -> conn
    end
  end

  defp _authorize_resource(conn, opts) do
    current_user_name = opts[:current_user] || Application.get_env(:auth_ex, :current_user, :current_user)
    current_user = Dict.fetch! conn.assigns, current_user_name
    action = get_action(conn)

    resource = cond do
      action in [:index, :new, :create] ->
        opts[:model]
      true      ->
        fetch_resource(conn, opts)
    end

    case current_user |> Application.get_env(:auth_ex, :ability).authorized? action, resource do
      true  ->
        %{ conn | assigns: Map.put(conn.assigns, :authorized, true) }
      false ->
        %{ conn | assigns: Map.put(conn.assigns, :authorized, false) }
    end
  end

  def load_and_authorize_resource(conn, opts) do
    conn
    |> action_valid?(opts)
    |> case do
      true  -> _load_and_authorize_resource(conn, opts)
      false -> conn
    end
  end

  defp _load_and_authorize_resource(conn, opts) do
    conn
    |> load_resource(opts)
    |> authorize_resource(opts)
    |> purge_resource_if_unauthorized(opts)
  end

  defp purge_resource_if_unauthorized(conn = %{assigns: %{authorized: true}}, _), do: conn
  defp purge_resource_if_unauthorized(conn = %{assigns: %{authorized: false}}, opts) do
    %{ conn | assigns: Map.put(conn.assigns, resource_name(conn, opts), nil) }
  end
  
  defp get_action(conn) do
    conn.assigns
    |> Map.fetch(:action)
    |> case do
      {:ok, action} -> action
      _             -> conn.private.phoenix_action
    end
  end

  defp action_exempt?(conn, opts) do
    action = get_action(conn)

    (is_list(opts[:except]) && action in opts[:except])
    |> case do
      true  -> true
      false -> action == opts[:except]
    end
  end

  defp action_included?(conn, opts) do
    action = get_action(conn)

    (is_list(opts[:only]) && action in opts[:only])
    |> case do
      true  -> true
      false -> action == opts[:only]
    end
  end

  defp action_valid?(conn, opts) do
    cond do
      has_key?(opts, :except) && has_key?(opts, :only) ->
        false
      has_key?(opts, :except) ->
        !action_exempt?(conn, opts)
      has_key?(opts, :only) ->
        action_included?(conn, opts)
      true ->
        true
    end
  end

  defp fetch_resource(conn, opts) do
    repo = Application.get_env(:auth_ex, :repo)
    conn
    |> Map.fetch(resource_name(conn, opts))
    |> case do
      :error ->
        repo.get(opts[:model], conn.params["id"])
      {:ok, nil} ->
        repo.get(opts[:model], conn.params["id"])
      {:ok, resource} -> # if there is already a resource loaded onto the conn
        case (resource.__struct__ == opts[:model]) do
          true  ->
            resource
          false ->
            repo.get(opts[:model], conn.params["id"])
        end
    end
  end

  defp fetch_all(conn, opts) do

    Logger.info "1. fetch all"
    conn
    |> Map.fetch(resource_name(conn, opts))
    |> case do
      :error ->
        Logger.info "2. fetch all"
        conn
        |> user_model(opts)
        |> Application.get_env(:auth_ex, :ability).load_resource(get_action(conn), opts[:model])
      {:ok, resource} ->
        case (resource.__struct__ == opts[:model]) do
          true  ->
            Logger.info "3. fetch all"
            resource
          false ->
            Logger.info "4. fetch all"
            conn
            |> user_model(opts)
            |> Application.get_env(:auth_ex, :ability).load_resource(get_action(conn), opts[:model])
        end
    end
  end

  defp user_model(conn, opts) do
    current_user_name = opts[:current_user] || Application.get_env(:auth_ex, :current_user, :current_user)
    Dict.fetch! conn.assigns, current_user_name
  end

  defp resource_name(conn, opts) do
    res = case opts[:as] do
      nil ->
        opts[:model]
        |> Atom.to_string
        |> String.split(".")
        |> List.last
        |> Mix.Utils.underscore
        |> pluralize_if_needed(conn)
        |> String.to_atom
      as -> as
    end
    Logger.debug("resource_name: #{inspect res}")
    res
  end

  defp pluralize_if_needed(name, conn) do
    case get_action(conn) in [:index] do
      true -> name <> "s"
      _    -> name
    end
  end
end
