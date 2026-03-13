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
      |> Finpes.Finance.create_user_category()

    category
  end

  @doc """
  Generate a transaction.
  """
  def transaction_fixture(attrs \\ %{}) do
    {:ok, transaction} =
      attrs
      |> Enum.into(%{
        amount: 42,
        description: "some description",
        expected_date: ~D[2026-03-12],
        ignore_in_reports: true,
        installment: "some installment",
        paid_date: ~D[2026-03-12],
        recurrence_group_id: "some recurrence_group_id",
        status: "some status",
        transfer_id: "some transfer_id",
        type: "some type"
      })
      |> Finpes.Finance.create_user_transaction()

    transaction
  end
end
