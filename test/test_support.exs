defmodule Test.User do
  use Ecto.Model
  schema "users" do
    field :name, :string
    field :admin?, :boolean
    belongs_to :account, Test.Account
    has_many :users_roles, Test.UserRole
    has_many :roles, through: [:users_roles, :role]
  end
end
defmodule Test.Role do
  use Ecto.Model
  schema "roles" do
    field :name, :string
    has_many :users_roles, Test.UserRole 
    has_many :users, through: [:users_roles, :user]
  end
end
defmodule Test.UserRole do
  use Ecto.Model
  @primary_key false
  schema "users_roles" do
    belongs_to :user, Test.User, references: :id 
    belongs_to :role, Test.Role, references: :id 
  end
end
defmodule Test.Account do
  use Ecto.Model
  schema "accounts" do
    field :username, :string
    has_many :users, Test.User
  end
end
defmodule Test.Asset do
  use Ecto.Model
  schema "assets" do
    field :user_id, :integer
  end
  #defstruct id: nil, name: "", user_id: nil
end
defmodule Test.Inventory do
  use Ecto.Model
  schema "assets" do
    belongs_to :user, Test.User
    belongs_to :asset, Test.Asset
  end
end
defmodule Test.Item do
  use Ecto.Model
  schema "items" do
    field :name, :string
    belongs_to :account, Test.Account
    belongs_to :user, Test.User
  end
end

#    can :index, Test.Item, user: [roles: [name: ~w(admin superadmin)]]
# User |> join(:inner, [u], ur in UserRole, ur.user_id == u.id) 
# |> join(:inner, [u, ur], r in Role, ur.role_id == r.id and r.name in ~w(admin superadmin)) 
# |> preload([:roles]) |> Repo.all 

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

    can :index, Test.Inventory, user_id: user.id, asset_id: 3

    #can :index, Test.Item, user: [account_id: user.account_id]
    can :index, Test.Item, preload: [user: [:roles]], user: %{roles: %{name: ~w(admin superadmin)}}
  end
end

