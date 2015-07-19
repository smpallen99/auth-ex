defmodule AuthEx.Builder.Test do
  use ExUnit.Case
  require Ecto.Query
  import Ecto.Query

  @ability_blocks [%{actions: [:index, :show, :create, :update, :new, :edit, :destroy], can: true,
     module: Test.User, opts: []},
   %{actions: [:index], can: true, module: Test.Account, opts: []},
   %{actions: [:index, :show, :create, :update, :new, :edit, :destroy], can: true,
     module: Test.Asset, opts: [user_id: 1]},
   %{actions: [:create], can: true, module: Test.Asset, opts: [id: [4, 5]]},
   %{actions: [:index], can: true, module: Test.Inventory,
     opts: [user_id: 1, asset_id: 3]},
   %{actions: [:index], can: true, module: Test.Item,
     opts: [preload: [user: [:roles]],
      user: %{roles: %{name: ["admin", "superadmin"]}}]}]


    test "nested join" do
      item = 
        %{actions: [:index], can: true, module: Test.Item,
          opts: [preload: [user: [:roles]],
          user: %{roles: %{name: ["admin", "superadmin"]}}]}

      model = %Test.Item{}
      query = from r in model.__struct__

      result = AuthEx.Builder.build_query(item[:opts], :index, model, 0, query)
      expected = ~s(#Ecto.Query<from i in Test.Item, join: u0 in Test.User, on: i.user_id == u0.id, join: u1 in Test.UserRole, on: u0.id == u1.user_id, join: r in Test.Role, on: u1.role_id == r.id, where: r.name in ^["admin", "superadmin"], preload: [user: [:roles]]>)
      IO.puts "result: #{inspect result}"
      assert inspect(result) == expected
    end

    test "where in list" do
      item = 
        %{actions: [:index, :show, :create, :update, :new, :edit, :destroy], can: true,
          module: Test.Asset, opts: [user_id: 1]}
      model = %Test.Asset{}
      query = from r in model.__struct__

      result = AuthEx.Builder.build_query(item[:opts], :index, model, 0, query)
      assert inspect(result) == "#Ecto.Query<from a in Test.Asset, where: a.user_id == ^1>"
    end
    test "compound where" do
      item = 
        %{actions: [:index], can: true, module: Test.Inventory,
          opts: [user_id: 1, asset_id: 3]}
      model = %Test.Inventory{}
      query = from r in model.__struct__

      result = AuthEx.Builder.build_query(item[:opts], :index, model, 0, query)
      #IO.puts "result: #{inspect result}"
      assert inspect(result) == ~s(#Ecto.Query<from i in Test.Inventory, where: i.user_id == ^1, where: i.asset_id == ^3>)
    end
    test "no where" do
      item = %{actions: [:index], can: true, module: Test.Account, opts: []}
      model = %Test.Account{}
      query = from r in model.__struct__

      result = AuthEx.Builder.build_query(item[:opts], :index, model, 0, query)
      #IO.puts "result: #{inspect result}"
      assert inspect(result) == ~s(#Ecto.Query<from a in Test.Account>)
    end
  end
