defmodule Finpes.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:wallets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :type, :string, null: false
      add :initial_balance, :integer, default: 0
      add :color, :string
      add :icon, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)



      timestamps(type: :utc_datetime)
    end

    create index(:wallets, [:user_id])
  end
end
