defmodule Finpes.Finance.Category do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "categories" do
    field :name, :string
    field :type, :string
    field :classification, :string
    field :color, :string
    field :icon, :string

    belongs_to :user, Finpes.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :type, :classification, :color, :icon, :user_id])
    |> validate_required([:name, :type, :classification, :user_id], message: "não pode ficar em branco ")
    |> validate_inclusion(:type, ["expense", "income"], message: "deve ser 'income' ou 'expense'")
    |> validate_inclusion(:classification, ["essential", "optional", "savings"], message: "deve ser 'essential', 'optional' ou 'savings'")
  end
end
