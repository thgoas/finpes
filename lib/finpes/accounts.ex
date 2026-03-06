defmodule Finpes.Accounts do
  @moduledoc """
  The Accounts context.
  """
  alias Finpes.Accounts.UserToken
  import Ecto.Query, warn: false
  alias Finpes.Repo

  alias Finpes.Accounts.User

  @token_salt "api_auth_session_salt"

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  alias Finpes.Accounts.UserToken

  @doc """
  Returns the list of user_tokens.

  ## Examples

      iex> list_user_tokens()
      [%UserToken{}, ...]

  """
  def list_user_tokens do
    Repo.all(UserToken)
  end

  @doc """
  Gets a single user_token.

  Raises `Ecto.NoResultsError` if the User token does not exist.

  ## Examples

      iex> get_user_token!(123)
      %UserToken{}

      iex> get_user_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_token!(id), do: Repo.get!(UserToken, id)

  @doc """
  Creates a user_token.

  ## Examples

      iex> create_user_token(%{field: value})
      {:ok, %UserToken{}}

      iex> create_user_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_token(attrs) do
    %UserToken{}
    |> UserToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_token.

  ## Examples

      iex> update_user_token(user_token, %{field: new_value})
      {:ok, %UserToken{}}

      iex> update_user_token(user_token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_token(%UserToken{} = user_token, attrs) do
    user_token
    |> UserToken.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_token.

  ## Examples

      iex> delete_user_token(user_token)
      {:ok, %UserToken{}}

      iex> delete_user_token(user_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_token(%UserToken{} = user_token) do
    Repo.delete(user_token)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_token changes.

  ## Examples

      iex> change_user_token(user_token)
      %Ecto.Changeset{data: %UserToken{}}

  """
  def change_user_token(%UserToken{} = user_token, attrs \\ %{}) do
    UserToken.changeset(user_token, attrs)
  end

  # lib/api_auth/accounts.ex

  # ... (mantenha as funções que já estão aí) ...

  @doc """
  Tenta encontrar o usuário pelo e-mail e verifica se a senha bate com o hash.
  """
  def authenticate_user(email, password) do
    # 1. Busca o usuário no banco
    user = Repo.get_by(User, email: email)

    cond do
      # 2. Se achou o usuário E a senha informada bate com o hash do banco: Sucesso!
      user && Argon2.verify_pass(password, user.password_hash) ->
        {:ok, user}

      # 3. Se o usuário existe, mas a senha está errada
      user ->
        {:error, :unauthorized}

      # 4. Se o usuário não existe
      true ->
        # IMPORTANTE: Chamamos essa função dummy do Argon2 para evitar "Timing Attacks".
        # Isso faz a requisição demorar o mesmo tempo, quer o email exista ou não.
        Argon2.no_user_verify()
        {:error, :not_found}
    end
  end

  @doc """
  Gera um token assinado para o usuário e salva no banco de dados.
  """
  def generate_user_session_token(user) do
    # 1. Assina o token com o ID do usuário
    token = Phoenix.Token.sign(FinpesWeb.Endpoint, @token_salt, user.id)

    # 2. Salva o token na tabela user_tokens associado a este usuário
    %UserToken{user_id: user.id, token: token}
    |> Repo.insert!()

    token
  end

  @doc """
  Verifica a validade do token e se ele ainda existe no banco (não sofreu logout).
  """
  def verify_session_token(token) do
    # max_age é em segundos. Exemplo: 30 dias (30 * 86400 = 2592000)
    case Phoenix.Token.verify(FinpesWeb.Endpoint, @token_salt, token, max_age: 2_592_000) do
      {:ok, user_id} ->
        # Se a assinatura é válida e não expirou, verificamos se o token não foi apagado
        if Repo.exists?(from t in UserToken, where: t.token == ^token) do
          {:ok, user_id}
        else
          {:error, :revoked} # Token foi deletado do banco (usuário fez logout)
        end

      {:error, _reason} = error ->
        error # Retorna :expired ou :invalid
    end
  end

  @doc """
  Deleta o token do banco de dados (Efetua o Logout).
  """
  def delete_session_token(token) do
    from(t in UserToken, where: t.token == ^token)
    |> Repo.delete_all()
  end
end
