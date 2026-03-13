defmodule Finpes.Finance.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :description, :string
    field :amount, :integer
    field :type, :string
    field :status, :string
    field :expected_date, :date
    field :paid_date, :date
    field :installment, :string
    field :recurrence_group_id, :string
    field :transfer_id, :string
    field :ignore_in_reports, :boolean, default: false

    belongs_to :user, Finpes.Accounts.User
    belongs_to :wallet, Finpes.Finance.Wallet
    belongs_to :category, Finpes.Finance.Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :description, :amount, :type, :status, :expected_date, :paid_date,
      :installment, :recurrence_group_id, :transfer_id, :ignore_in_reports,
      :user_id, :wallet_id, :category_id
    ])
    |> validate_required([:description, :amount, :type, :status, :expected_date, :user_id, :wallet_id], message: "não pode ficar em branco")
    |> validate_number(:amount, greater_than: 0, message: "O valor deve ser maior que zero (em centavos)")
    |> validate_inclusion(:type, ["income", "expense", "transfer"], message: "deve ser 'income', 'expense' ou 'transfer'")
    |> validate_inclusion(:status, ["pending", "paid"], message: "deve ser 'pending' ou 'paid'")
    # Garante que as chaves estrangeiras realmente existem no banco
    |> foreign_key_constraint(:wallet_id, message: "Carteira não encontrada")
    |> foreign_key_constraint(:category_id, message: "Categoria não encontrada")
  end
end
