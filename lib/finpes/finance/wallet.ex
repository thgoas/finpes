defmodule Finpes.Finance.Wallet do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "wallets" do
    field :name, :string
    field :type, :string
    field :initial_balance, :integer, default: 0
    field :color, :string
    field :icon, :string


    belongs_to :user, Finpes.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :type, :initial_balance, :color, :icon, :user_id])
    |> validate_required([:name, :type, :user_id], message: "não pode ficar em branco ")
    |> validate_inclusion(:type, ["checking", "savings", "credit_card", "cash"], message: "inválido")
    |> validate_number(:initial_balance, message: "O saldo inicial deve ser um valor inteiro (centavos).")
  end
end
