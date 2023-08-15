defmodule Lv.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lv.Accounts` context.
  """

  def unique_user_email, do: "#{Faker.Person.first_name()}#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"
  def valid_username, do: "#{Faker.Person.first_name()}-#{System.unique_integer([:positive])}"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      username: valid_username()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Lv.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
