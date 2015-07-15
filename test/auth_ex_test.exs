defmodule Test.User do
  defstruct id: nil, name: "", admin?: false
end
defmodule Test.Account do
  defstruct id: nil, name: ""
end
defmodule Test.Asset do
  defstruct id: nil, name: "", user_id: nil
end

defmodule Test.Ability do
  use AuthEx.Ability

  abilities user do
    can :manage, Test.User
    can :index, Test.Account

    can :manage, Test.Asset, user_id: user.id

    if user.admin? do
      can :edit, Test.Asset
    end
    can :create, Test.Asset, id: [4, 5]
  end
end

defmodule AuthExTest do
  use ExUnit.Case

  setup do
    {:ok, user: %Test.User{id: 1}}
  end

  test "valid User index", meta do
    assert Test.Ability.handle_ability(meta[:user], :index, %Test.User{})
  end

  test "valid Account index", meta do
    assert Test.Ability.handle_ability(meta[:user], :index, %Test.Account{})
  end

  test "invalid Asset index", meta do
    refute Test.Ability.handle_ability(meta[:user], :index, %Test.Asset{})
  end

  test "valid Asset index", meta do
    assert Test.Ability.handle_ability(meta[:user], :index, %Test.Asset{user_id: 1})
  end

  test "invalid user_id asset index", meta do
    refute Test.Ability.handle_ability(meta[:user], :index, %Test.Asset{user_id: 2})
  end

  test "valid admin asset edit", meta do
    user = struct meta[:user], admin?: true
    assert Test.Ability.handle_ability(user, :edit, %Test.Asset{user_id: 2})
  end

  test "invalid admin asset edit", meta do
    user = struct meta[:user]
    refute Test.Ability.handle_ability(user, :edit, %Test.Asset{user_id: 2})
  end
  test "valid list", meta do
    assert Test.Ability.handle_ability(meta[:user], :create, %Test.Asset{id: 4})
    assert Test.Ability.handle_ability(meta[:user], :create, %Test.Asset{id: 5})
  end
  test "invalid list", meta do
    refute Test.Ability.handle_ability(meta[:user], :create, %Test.Asset{id: 3})
  end
end
