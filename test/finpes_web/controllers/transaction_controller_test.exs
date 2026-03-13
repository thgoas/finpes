defmodule FinpesWeb.TransactionControllerTest do
  use FinpesWeb.ConnCase

  alias Finpes.Accounts
  alias Finpes.Finance

  @user_attrs %{
    "name" => "Thiago Transações",
    "email" => "thiago.trans@finpes.com",
    "password" => "SenhaForte@123"
  }

  @valid_wallet_attrs %{
    "name" => "Conta Corrente",
    "type" => "checking",
    "initial_balance" => 1000
  }

  @valid_category_attrs %{
    "name" => "Supermercado",
    "type" => "expense",
    "classification" => "essential"
  }

  @invalid_attrs %{
    "description" => "",
    "amount" => -100,
    "type" => "investimento"
  }

  # No setup, precisamos criar o usuário, logar, criar a carteira e a categoria,
  # e passar os IDs deles adiante para os testes usarem.
  setup %{conn: conn} do
    {:ok, user} = Accounts.create_user(@user_attrs)
    token = Accounts.generate_user_session_token(user)

    {:ok, wallet} = Finance.create_user_wallet(user.id, @valid_wallet_attrs)
    {:ok, category} = Finance.create_user_category(user.id, @valid_category_attrs)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")

    %{conn: conn, user: user, wallet: wallet, category: category}
  end

  describe "CRUD de Transações" do
    test "Cria transação com sucesso", %{conn: conn, wallet: wallet, category: category} do
      valid_payload = %{
        "description" => "Netflix",
        "amount" => 5590, # R$ 55,90
        "type" => "expense",
        "status" => "paid",
        "expected_date" => "2026-03-12",
        "wallet_id" => wallet.id,
        "category_id" => category.id
      }

      conn = post(conn, "/api/transactions", valid_payload)

      resposta = json_response(conn, 201)
      assert resposta["message"] == "Transação criada"
      assert resposta["data"]["amount"] == 5590
      assert resposta["data"]["wallet_id"] == wallet.id
    end

    test "Retorna erros 422 para dados inválidos (como valor negativo)", %{conn: conn, wallet: wallet} do
      payload_invalido = Map.merge(@invalid_attrs, %{"wallet_id" => wallet.id})

      conn = post(conn, "/api/transactions", payload_invalido)

      erros = json_response(conn, 422)["errors"]

      assert List.first(erros["description"]) =~ "não pode ficar em branco"
      assert List.first(erros["amount"]) =~ "maior que zero"
      assert List.first(erros["type"]) =~ "deve ser 'income', 'expense' ou 'transfer'"
    end

    test "Atualiza e Deleta transação com sucesso", %{conn: conn, user: user, wallet: wallet} do
      # Cria a transação direto no banco para testar os endpoints de put/delete
      valid_payload = %{
        "description" => "Salário",
        "amount" => 500000,
        "type" => "income",
        "status" => "pending",
        "expected_date" => "2026-03-05",
        "wallet_id" => wallet.id
      }
      {:ok, t} = Finance.create_user_transaction(user.id, valid_payload)

      # Update
      conn_put = put(conn, "/api/transactions/#{t.id}", %{"status" => "paid", "amount" => 550000})
      assert json_response(conn_put, 200)["data"]["status"] == "paid"
      assert json_response(conn_put, 200)["data"]["amount"] == 550000

      # Delete
      conn_delete = delete(conn, "/api/transactions/#{t.id}")
      assert json_response(conn_delete, 200)["message"] =~ "excluída"
    end
  end
end
