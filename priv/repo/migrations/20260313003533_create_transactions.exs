defmodule Finpes.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :description, :string, null: false
      add :amount, :integer, null: false
      add :type, :string, null: false
      add :status, :string, null: false
      add :expected_date, :date, null: false
      add :paid_date, :date
      add :installment, :string
      add :recurrence_group_id, :string
      add :transfer_id, :string
      add :ignore_in_reports, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :wallet_id, references(:wallets, on_delete: :delete_all, type: :binary_id), null: false
      add :category_id, references(:categories, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:transactions, [:user_id])
    create index(:transactions, [:wallet_id])
    create index(:transactions, [:category_id])
    create index(:transactions, [:expected_date])
  end
end
