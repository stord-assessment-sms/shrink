defmodule Shrink.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Shrink.Repo

  def user_factory do
    %Shrink.Users.User{
      email: &Faker.Internet.email/0
    }
  end
end
