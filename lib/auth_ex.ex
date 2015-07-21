defmodule AuthEx do

  def can?(conn, action, model_name) do
    #Application.get_env(:auth_ex, :ability).valid_action?
  end
end
