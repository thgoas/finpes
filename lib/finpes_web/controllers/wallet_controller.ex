defmodule FinpesWeb.WalletController do
  use FinpesWeb, :controller
  alias Finpes.Finance

  # Helper para pegar o ID do usuário que o nosso Plug de Autenticação validou
  defp user_id(conn), do: conn.assigns.current_user_id

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  @doc """
  Lista TODAS as contas do usuário logado.
  """
  def index(conn, _params) do
    wallet = Finance.list_user_wallets(user_id(conn))
    json(conn, %{data: Enum.map(wallet, &format_wallet/1)})
  end

  @doc """
  Cria uma nova conta amarrada ao usuário logado.
  """
  def create(conn, wallet_params) do
    case Finance.create_user_wallet(user_id(conn), wallet_params) do
      {:ok, wallet} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Conta criada com sucesso", data: format_wallet(wallet)})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  @doc """
  Exibe os detalhes de uma única conta.
  """
  def show(conn, %{"id" => id}) do
    # O `get_user_wallet!` garante que a carteira existe E pertence a este usuário
    wallet = Finance.get_user_wallet!(user_id(conn), id)
    json(conn, %{data: format_wallet(wallet)})
  end

  @doc """
  Atualiza uma conta (ex: mudar o nome de "Nubank" para "Roxinho").
  """
  def update(conn, %{"id" => id} = wallet_params) do
    wallet = Finance.get_user_wallet!(user_id(conn), id)

    case Finance.update_wallet(wallet, wallet_params) do
      {:ok, updated_wallet} ->
        json(conn, %{message: "Conta atualizada", data: format_wallet(updated_wallet)})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  @doc """
  Deleta uma conta bancária.
  """
  def delete(conn, %{"id" => id}) do
    wallet = Finance.get_user_wallet!(user_id(conn), id)

    {:ok, _wallet} = Finance.delete_wallet(wallet)

    conn
    |> put_status(:ok)
    |> json(%{message: "Conta excluída com sucesso."})
  end

  # ---- FUNÇÕES PRIVADAS DE FORMATAÇÃO ----

  # Transforma o struct do banco de dados em um mapa limpo para o Frontend
  defp format_wallet(wallet) do
    %{
      id: wallet.id,
      name: wallet.name,
      type: wallet.type,
      initial_balance: wallet.initial_balance,
      color: wallet.color,
      icon: wallet.icon
    }
  end

  # Reaproveitamos o nosso formatador de erros para devolver mensagens claras
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
