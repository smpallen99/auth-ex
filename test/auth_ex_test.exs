defmodule AuthExTest do
  use ExUnit.Case
  require Ecto.Query
  import Ecto.Query

  defmodule Conn do
    defstruct assigns: %{}
  end

  setup do
    conn = %Conn{assigns: %{current_user: %Test.User{id: 1}}}
    {:ok, conn: conn }
  end

  test "can show", meta do
    assert AuthEx.can?(meta[:conn], :show, Test.User)
  end

  test "cannot edit", meta do
    refute AuthEx.can?(meta[:conn], :edit, Test.Account)
  end
end
