defmodule Finpes.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :name, :string
    field :email, :string
    field :password_hash, :string
    field :avatar_url, :string
    field :plan_role, :string, default: "free"
    field :payment_gateway_id, :string
    field :password, :string, virtual: true



    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :avatar_url])
    |> validate_required([:name, :email, :password])
    |> validate_length(:name, min: 3, message: "Nome deve ter pelo menos 3 caracteres.")
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "Formato de email inválido.")
    |> validate_format(:password, ~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,72}$/, message: "Senha deve conter pelos de 8 a 72 caracteres, Letras Maiúsculas, Minúsculas, Números e Caracteres Especiais.")
    # |> validate_length(:password, min: 6, max: 72, message: "Senha deve ter entre 6 e 72 caracteres.")
    |> unique_constraint(:email, message: "Email já cadastrado.")
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    # O Argon2.add_hash/1 coloca o hash gerado diretamente no campo :password_hash do changeset!
    put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))
  end

  # Se o changeset for inválido ou a senha não foi enviada, não fazemos nada
  defp put_password_hash(changeset), do: changeset
end
