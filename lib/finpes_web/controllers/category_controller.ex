defmodule FinpesWeb.CategoryController do
  use FinpesWeb, :controller
  alias Finpes.Finance

  defp user_id(conn), do: conn.assigns.current_user_id

  def index(conn, _params) do
    categories = Finance.list_user_categories(user_id(conn))
    json(conn, %{data: Enum.map(categories, &format_category/1)})
  end

  def create(conn, params) do
    case Finance.create_user_category(user_id(conn), params) do
      {:ok, category} ->
        conn |> put_status(:created) |> json(%{message: "Categoria criada", data: format_category(category)})
      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def show(conn, %{"id" => id}) do
    category = Finance.get_user_category!(user_id(conn), id)
    json(conn, %{data: format_category(category)})
  end

  def update(conn, %{"id" => id} = params) do
    category = Finance.get_user_category!(user_id(conn), id)
    case Finance.update_category(category, params) do
      {:ok, updated_category} ->
        json(conn, %{message: "Categoria atualizada", data: format_category(updated_category)})
      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    category = Finance.get_user_category!(user_id(conn), id)
    {:ok, _category} = Finance.delete_category(category)
    json(conn, %{message: "Categoria excluída"})
  end

  defp format_category(category) do
    %{id: category.id, name: category.name, type: category.type, classification: category.classification, color: category.color, icon: category.icon}
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
