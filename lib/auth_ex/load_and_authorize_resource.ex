  defmodule AuthEx.LoadAndAuthorizeResource do
    import AuthEx.Plugs
    require Logger

    def init(opts) do
      opts
    end

    # def call(conn, opts) when is_list(opts) do
    #   call conn, Enum.into(opts, %{})
    # end
    def call(conn, opts) do
      Logger.debug "#{__MODULE__}.call"
      load_and_authorize_resource(conn, opts)
    end
  end
