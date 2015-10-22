defmodule AuthEx do
  import AuthEx.Utils

  defmacro __using__(_) do
    quote do
      import AuthEx.Plugs
    end
  end

  def can?(conn, action, model) do
    conn
    |> current_user
    |> Application.get_env(:auth_ex, :ability).authorized?(normalize(action), model)
  end
  def cannot?(conn, action, model), do: !can?(conn, action, model)

  defp normalize(:read), do: :show
  defp normalize(:write), do: :edit
  defp normalize(:manage), do: :write
  defp normalize(other), do: other 
end
