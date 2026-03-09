defmodule FinpesWeb.WalletControllerTest do
  use FinpesWeb.ConnCase

  alias Finpes.Accounts
  alias Finpes.Finance

  @user_attrs %{
    "name" => "Thiago",
    "email" => "thiago@finpes.com",
    "password" => "SenhaForte@123"
  }

  @valid_wallet_attrs %{
    "name" => "Conta Corrente Nubank",
    "type" => "checking",
    "initial_balance" => 15050, # R$ 150,50 em centavos
    "color" => "#8A05BE",
    "icon" => "bank"
  }

  @invalid_wallet_attrs %{
    "name" => "", # Inválido: obrigatório
    "type" => "crypto", # Inválido: não está na lista permitida
    "initial_balance" => 150.50 # Inválido: float não é permitido, tem que ser inteiro
  }

  # Setup: Cria um usuário e injeta o token de autenticação na conexão
  setup %{conn: conn} do
    {:ok, user} = Accounts.create_user(@user_attrs)
    token = Accounts.generate_user_session_token(user)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")

    %{conn: conn, user: user}
  end

  describe "CRUD de Contas (Wallets)" do
    test "Lista apenas as contas do usuário logado (Tenant Isolation)", %{conn: conn, user: user} do
      # Cria uma conta para o usuário logado
      {:ok, _wallet} = Finance.create_user_wallet(user.id, @valid_wallet_attrs)
        # IO.inspect(wallet)
      # Cria um SEGUNDO usuário e uma conta para ele
      {:ok, outro_user} = Accounts.create_user(%{@user_attrs | "email" => "hacker@finpes.com"})
      {:ok, _outra_wallet} = Finance.create_user_wallet(outro_user.id, %{@valid_wallet_attrs | "name" => "Itaú do Hacker"})

      # Faz a requisição GET
      conn = get(conn, "/api/wallets")

      data = json_response(conn, 200)["data"]

      # Deve retornar apenas 1 conta (a do Thiago), ignorando a do Hacker
      assert length(data) == 1
      assert hd(data)["name"] == "Conta Corrente Nubank"
    end

    test "Cria conta com dados válidos e retorna 201 Created", %{conn: conn} do
      conn = post(conn, "/api/wallets", @valid_wallet_attrs)

      resposta = json_response(conn, 201)
      assert resposta["message"] == "Conta criada com sucesso"
      assert resposta["data"]["initial_balance"] == 15050
      assert resposta["data"]["type"] == "checking"
    end

    test "Retorna erros 422 ao tentar criar conta com dados inválidos", %{conn: conn} do
      conn = post(conn, "/api/wallets", @invalid_wallet_attrs)

      erros = json_response(conn, 422)["errors"]

      # Verifica as mensagens formatadas (usando String.equivalent? ou =~)
      assert List.first(erros["name"]) =~ "não pode ficar em branco"
      assert List.first(erros["type"]) =~ "inválido"
      assert List.first(erros["initial_balance"]) =~ "is invalid"
    end

    test "Atualiza uma conta com sucesso", %{conn: conn, user: user} do
      {:ok, wallet} = Finance.create_user_wallet(user.id, @valid_wallet_attrs)

      # Muda o nome e o tipo
      conn = put(conn, "/api/wallets/#{wallet.id}", %{"name" => "Poupança Caixa", "type" => "savings"})

      assert json_response(conn, 200)["data"]["name"] == "Poupança Caixa"
      assert json_response(conn, 200)["data"]["type"] == "savings"
    end

    test "Deleta uma conta com sucesso", %{conn: conn, user: user} do
      {:ok, wallet} = Finance.create_user_wallet(user.id, @valid_wallet_attrs)

      conn_delete = delete(conn, "/api/wallets/#{wallet.id}")
      assert json_response(conn_delete, 200)["message"] =~ "excluída"

      # Garante que não é mais possível encontrar a conta
      assert_raise Ecto.NoResultsError, fn ->
        Finance.get_user_wallet!(user.id, wallet.id)
      end
    end

    test "Garante que um usuário não pode acessar a conta de outro (404/NoResults)", %{conn: conn} do
      # Cria um segundo usuário dono de uma conta
      {:ok, outro_user} = Accounts.create_user(%{@user_attrs | "email" => "vitima@finpes.com"})
      {:ok, conta_da_vitima} = Finance.create_user_wallet(outro_user.id, @valid_wallet_attrs)

      # O usuário logado no "conn" tenta acessar a conta da vítima pelo ID
      # Como usamos Repo.one!(), o Ecto lança um erro que o Phoenix transforma em 404
      assert_raise Ecto.NoResultsError, fn ->
        get(conn, "/api/wallets/#{conta_da_vitima.id}")
      end
    end
  end
end
