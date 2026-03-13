defmodule FinpesWeb.TransactionController do
  use FinpesWeb, :controller
  alias Finpes.Finance

  defp user_id(conn), do: conn.assigns.current_user_id

  def index(conn, _params) do
    transactions = Finance.list_user_transactions(user_id(conn))
    json(conn, %{data: Enum.map(transactions, &format_transaction/1)})
  end

  def create(conn, params) do
    case Finance.create_user_transaction(user_id(conn), params) do
      {:ok, transaction} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Transação criada", data: format_transaction(transaction)})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def show(conn, %{"id" => id}) do
    transaction = Finance.get_user_transaction!(user_id(conn), id)
    json(conn, %{data: format_transaction(transaction)})
  end

  def update(conn, %{"id" => id} = params) do
    transaction = Finance.get_user_transaction!(user_id(conn), id)

    case Finance.update_transaction(transaction, params) do
      {:ok, updated_transaction} ->
        json(conn, %{message: "Transação atualizada", data: format_transaction(updated_transaction)})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    transaction = Finance.get_user_transaction!(user_id(conn), id)
    {:ok, _transaction} = Finance.delete_transaction(transaction)

    json(conn, %{message: "Transação excluída"})
  end

  # ---- FORMATADORES ----

  defp format_transaction(t) do
    %{
      id: t.id,
      description: t.description,
      amount: t.amount,
      type: t.type,
      status: t.status,
      expected_date: t.expected_date,
      paid_date: t.paid_date,
      installment: t.installment,
      recurrence_group_id: t.recurrence_group_id,
      transfer_id: t.transfer_id,
      ignore_in_reports: t.ignore_in_reports,
      wallet_id: t.wallet_id,
      category_id: t.category_id
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
