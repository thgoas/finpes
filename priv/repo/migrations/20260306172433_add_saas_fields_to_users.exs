defmodule Finpes.Repo.Migrations.AddSaasFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :plan_role, :string,  default: "free"
      add :payment_gateway_id, :string
    end

    create index(:users, [:payment_gateway_id])
  end
end
