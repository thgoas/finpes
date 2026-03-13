defmodule FinpesWeb.CategoryControllerTest do
  use FinpesWeb.ConnCase

  alias Finpes.Accounts
  alias Finpes.Finance

  @user_attrs %{
    "name" => "Thiago Categorias",
    "email" => "thiago.cat@finpes.com",
    "password" => "SenhaForte@123"
  }

  @valid_attrs %{
    "name" => "Mercado",
    "type" => "expense",
    "classification" => "essential",
    "color" => "#EF4444",
    "icon" => "shopping-cart"
  }

  @invalid_attrs %{
    "name" => "",
    "type" => "receita", # Inválido (deve ser income ou expense)
    "classification" => "superfluo" # Inválido (deve ser essential, optional ou savings)
  }

  setup %{conn: conn} do
    {:ok, user} = Accounts.create_user(@user_attrs)
    token = Accounts.generate_user_session_token(user)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")

    %{conn: conn, user: user}
  end

  describe "CRUD de Categorias" do
    test "Lista categorias protegendo o Tenant Isolation", %{conn: conn, user: user} do
      {:ok, _cat} = Finance.create_user_category(user.id, @valid_attrs)

      {:ok, hacker} = Accounts.create_user(%{@user_attrs | "email" => "hacker.cat@finpes.com"})
      {:ok, _hacker_cat} = Finance.create_user_category(hacker.id, %{@valid_attrs | "name" => "Roubo"})

      conn = get(conn, "/api/categories")
      data = json_response(conn, 200)["data"]

      assert length(data) == 1
      assert hd(data)["name"] == "Mercado"
    end

    test "Cria categoria com sucesso (Regra 50/30/20)", %{conn: conn} do
      conn = post(conn, "/api/categories", @valid_attrs)

      resposta = json_response(conn, 201)
      assert resposta["message"] == "Categoria criada"
      assert resposta["data"]["classification"] == "essential"
    end

    test "Retorna erros 422 com mensagens traduzidas para dados inválidos", %{conn: conn} do
      conn = post(conn, "/api/categories", @invalid_attrs)

      erros = json_response(conn, 422)["errors"]

      assert List.first(erros["name"]) =~ "não pode ficar em branco"
      assert List.first(erros["type"]) =~ "deve ser 'income' ou 'expense'"
      assert List.first(erros["classification"]) =~ "deve ser 'essential', 'optional' ou 'savings'"
    end

    test "Atualiza e Deleta categoria com sucesso", %{conn: conn, user: user} do
      {:ok, cat} = Finance.create_user_category(user.id, @valid_attrs)

      # Teste de Update
      conn_put = put(conn, "/api/categories/#{cat.id}", %{"classification" => "optional", "name" => "Ifood"})
      assert json_response(conn_put, 200)["data"]["classification"] == "optional"

      # Teste de Delete
      conn_delete = delete(conn, "/api/categories/#{cat.id}")
      assert json_response(conn_delete, 200)["message"] =~ "excluída"
    end
  end
end
