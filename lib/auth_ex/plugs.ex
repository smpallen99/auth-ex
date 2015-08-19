defmodule AuthEx.Plugs do
  @debug false
  import Keyword, only: [has_key?: 2]
  import AuthEx.Utils, except: [debug: 1]
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
    {loaded_resource, key} = case get_action(conn) do
      :index  ->
        {fetch_all(conn, opts), Application.get_env(:auth_ex, :resources_key)} 
      :new    ->
        {nil, nil}
      :create ->
        {nil, nil}
      _       ->
        {fetch_resource(conn, opts), nil}
    end
    case key do
      nil -> 
        %{ conn | assigns: Map.put(conn.assigns, resource_name(conn, opts), loaded_resource) }
      key -> 
        %{ conn | assigns: Map.put(conn.assigns, key, loaded_resource) }
    end
  end

  def authorize_resource(conn, opts) do
    debug "authorize_resource: action_valid?: #{inspect action_valid?(conn, opts)}"
    conn
    |> action_valid?(opts)
    |> case do
      true  -> _authorize_resource(conn, opts)
      false -> conn
    end
  end

  defp _authorize_resource(conn, opts) do
    action = get_action(conn)

    resource = cond do
      action in [:index, :new, :create] ->
        opts[:model]
      true      ->
        fetch_resource(conn, opts)
    end
    debug "_authorize_resource: action: #{inspect action}"
    debug ""

    case current_user(conn, opts) |> Application.get_env(:auth_ex, :ability).authorized? action, resource do
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
        debug "-----> fetch_resource: 1."
        res = conn
        |> current_user(opts)
        |> Application.get_env(:auth_ex, :ability).load_resource(conn, get_action(conn), opts[:model])
        debug " ----- fetch result  #{inspect res}" <> "**********************\n"
        if is_list(res), do: debug("res count: #{Enum.count(res)}")
        res
        #repo.get(opts[:model], conn.params["id"])
      {:ok, nil} ->
        debug "-----> fetch_resource: 2."
        res = conn
        |> current_user(opts)
        |> Application.get_env(:auth_ex, :ability).load_resource(conn, get_action(conn), opts[:model])
        debug " ----- fetch result  #{inspect res}" <> "**********************\n"
        res
        #repo.get(opts[:model], conn.params["id"])
      {:ok, resource} -> # if there is already a resource loaded onto the conn
        case (resource.__struct__ == opts[:model]) do
          true  ->
            debug "-----> fetch_resource: 3."
            debug " ----- fetch result  #{inspect resource}" <> "**********************\n"
            resource
          false ->
            debug "-----> fetch_resource: 4."
            res = conn
            |> current_user(opts)
            |> Application.get_env(:auth_ex, :ability).load_resource(conn, get_action(conn), opts[:model])
            debug " ----- fetch result  #{inspect res}" <> "**********************\n"
            res
            #repo.get(opts[:model], conn.params["id"])
        end
    end
  end

  defp fetch_all(conn, opts) do

    conn
    |> Map.fetch(resource_name(conn, opts))
    |> case do
      :error ->
        conn
        |> current_user(opts)
        |> Application.get_env(:auth_ex, :ability).load_resource(conn, get_action(conn), opts[:model])
      {:ok, resource} ->
        case (resource.__struct__ == opts[:model]) do
          true  ->
            resource
          false ->
            conn
            |> current_user(opts)
            |> Application.get_env(:auth_ex, :ability).load_resource(conn, get_action(conn), opts[:model])
        end
    end
  end

  defp debug(message) do
    if @debug do
      IO.puts "ExAuth Debug: " <> message
    end
  end
end
