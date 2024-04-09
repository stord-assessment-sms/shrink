defmodule Shrink.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Shrink.Repo

  def link_factory do
    %Shrink.Links.Link{
      original_url: &Faker.Internet.url/0,
      user: fn -> build(:user) end
    }
  end

  def user_factory do
    %Shrink.Users.User{
      email: &Faker.Internet.email/0
    }
  end
end
