defmodule Finpes.FinanceFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Finpes.Finance` context.
  """

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        classification: "some classification",
        color: "some color",
        icon: "some icon",
        name: "some name",
        type: "some type"
      })
      |> Finpes.Finance.create_category()

    category
  end
end
