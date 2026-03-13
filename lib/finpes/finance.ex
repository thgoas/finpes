defmodule Finpes.Finance do
  @moduledoc """
  The Finance context.
  """

  import Ecto.Query, warn: false
  alias Finpes.Repo

  alias Finpes.Finance.Wallet

  @doc """
  Retorna TODAS as contas, mas APENAS do usuário logado.
  """
  def list_user_wallets(user_id) do
    from(a in Wallet, where: a.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Busca UMA carteira específica, garantindo que pertence ao usuário logado.
  """
  def get_user_wallet!(user_id, id) do
    from(a in Wallet, where: a.id == ^id and a.user_id == ^user_id)
    |> Repo.one!()
  end

 @doc """
  Cria uma carteira já amarrando ao ID do usuário.
  """
  def create_user_wallet(user_id, attrs \\ %{}) do
    # 1. Normalizamos o mapa: transformamos todas as chaves (sejam atoms ou strings) em strings.
    normalized_attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)

    # 2. Agora podemos injetar a chave "user_id" como string sem causar mistura de tipos
    final_attrs = Map.put(normalized_attrs, "user_id", user_id)

    %Wallet{}
    |> Wallet.changeset(final_attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a wallet.

  ## Examples

      iex> update_wallet(wallet, %{field: new_value})
      {:ok, %Wallet{}}

      iex> update_wallet(wallet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_wallet(%Wallet{} = wallet, attrs) do
    wallet
    |> Wallet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a wallet.

  ## Examples

      iex> delete_wallet(wallet)
      {:ok, %Wallet{}}

      iex> delete_wallet(wallet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_wallet(%Wallet{} = wallet) do
    Repo.delete(wallet)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking wallet changes.

  ## Examples

      iex> change_wallet(wallet)
      %Ecto.Changeset{data: %Wallet{}}

  """
  def change_wallet(%Wallet{} = wallet, attrs \\ %{}) do
    Wallet.changeset(wallet, attrs)
  end

  alias Finpes.Finance.Category

  @doc """
  Retorna TODAS as categorias do usuário logado.
  """
  def list_user_categories(user_id) do
    from(c in Category, where: c.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Busca UMA categoria específica do usuário.
  """
  def get_user_category!(user_id, id) do
    from(c in Category, where: c.id == ^id and c.user_id == ^user_id)
    |> Repo.one!()
  end

  @doc """
  Cria uma categoria atrelada ao usuário (seguro contra chaves mistas).
  """
  def create_user_category(user_id, attrs \\ %{}) do
    normalized_attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
    final_attrs = Map.put(normalized_attrs, "user_id", user_id)

    %Category{}
    |> Category.changeset(final_attrs)
    |> Repo.insert()
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  alias Finpes.Finance.Transaction

  @doc """
  Retorna TODAS as transações do usuário logado.
  """
  def list_user_transactions(user_id) do
    from(t in Transaction, where: t.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Busca UMA transação específica do usuário.
  """
  def get_user_transaction!(user_id, id) do
    from(t in Transaction, where: t.id == ^id and t.user_id == ^user_id)
    |> Repo.one!()
  end

  @doc """
  Cria uma transação, garantindo Tenant Isolation e Posse da Carteira.
  """
  def create_user_transaction(user_id, attrs \\ %{}) do
    normalized_attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
    final_attrs = Map.put(normalized_attrs, "user_id", user_id)

    # SEGURANÇA MÁXIMA: Verifica se o wallet_id enviado realmente pertence a este usuário.
    # Se ele mandar o ID da carteira de outra pessoa, o get_user_wallet! levanta um erro
    # e corta a requisição na hora, antes mesmo de bater no Changeset.
    wallet_id = Map.get(final_attrs, "wallet_id")
    if wallet_id, do: get_user_wallet!(user_id, wallet_id)

    %Transaction{}
    |> Transaction.changeset(final_attrs)
    |> Repo.insert()
  end

  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end
end
