  defmodule AuthorizeResource do
    import AuthEx.Plugs

    def init(opts) do
      opts
    end

    # def call(conn, opts) when is_list(opts) do
    #   call conn, Enum.into(opts, %{})
    # end
    def call(conn, opts) do
      authorize_resource(conn, opts)
    end
  end
