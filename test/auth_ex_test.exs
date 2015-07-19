defmodule AuthExTest do
  use ExUnit.Case
  require Ecto.Query
  import Ecto.Query

  setup do
    {:ok, user: %Test.User{id: 1}}
  end

  test "valid User index", meta do
    assert Test.Ability.authorized?(meta[:user], :index, %Test.User{})
  end

  test "valid Account index", meta do
    assert Test.Ability.authorized?(meta[:user], :index, %Test.Account{})
  end

  test "invalid Asset index", meta do
    refute Test.Ability.authorized?(meta[:user], :index, %Test.Asset{})
  end

  test "valid Asset index", meta do
    assert Test.Ability.authorized?(meta[:user], :index, %Test.Asset{user_id: 1})
  end

  test "invalid user_id asset index", meta do
    refute Test.Ability.authorized?(meta[:user], :index, %Test.Asset{user_id: 2})
  end

  test "valid admin asset edit", meta do
    user = struct meta[:user], admin?: true
    assert Test.Ability.authorized?(user, :edit, %Test.Asset{user_id: 2})
  end

  test "invalid admin asset edit", meta do
    user = struct meta[:user]
    refute Test.Ability.authorized?(user, :edit, %Test.Asset{user_id: 2})
  end
  test "valid list", meta do
    assert Test.Ability.authorized?(meta[:user], :create, %Test.Asset{id: 4})
    assert Test.Ability.authorized?(meta[:user], :create, %Test.Asset{id: 5})
  end
  test "invalid list", meta do
    refute Test.Ability.authorized?(meta[:user], :create, %Test.Asset{id: 3})
  end

  # test "load resource with 1 field match", meta do
  #   id = 1
  #   query = from i in Test.Asset, where: i.user_id == ^id
  #   res = Test.Ability.load_resource(meta[:user], :index, %Test.Asset{user_id: 1}) 
  #   assert inspect(res) == inspect(query)
  # end
  # test "load resrouce with 2 fields match", meta do
  #   user_id = 1
  #   asset_id = 3
  #   query = from i in Test.Inventory, where: i.asset_id == ^asset_id, where: i.user_id == ^user_id
  #   res = Test.Ability.load_resource(meta[:user], :index, %Test.Inventory{user_id: 1, asset_id: 3})
  #   assert inspect(res) == inspect(query)
  # end

  # test "nest attributes", meta do
  #   user_id = meta[:user]
  #   query = from i in Test.Item, join: u in Test.User, on: i.user_id == u.id, where: u.account_id == ^user_id
  #   res = Test.Ability.load_resource(meta[:user], :index, %Test.Item{})
  #   assert inspect(res) == inspect(query)
  # end
end
