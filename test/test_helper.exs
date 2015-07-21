Code.require_file "../test_support.exs", __ENV__.file
Application.put_env(:auth_ex, :ability, Test.Ability)
ExUnit.start()
