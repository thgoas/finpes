defmodule FinpesWeb.ProAccessTest do
  use FinpesWeb.ConnCase

  alias Finpes.Accounts

  @free_attrs %{
    "name" => "João Free",
    "email" => "free@finpes.com",
    "password" => "Senha@123"
  }

  @pro_attrs %{
    "name" => "Maria VIP",
    "email" => "pro@finpes.com",
    "password" => "Senha@123"
  }

  setup %{conn: conn} do
    # Prepara a conexão para aceitar e retornar JSON
    %{conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "Controle de Acesso em Rotas /api/pro" do
    test "Usuário FREE recebe 403 Forbidden ao tentar acessar rota PRO", %{conn: conn} do
      # 1. Cria o usuário Free
      {:ok, free_user} = Accounts.create_user(@free_attrs)

      # 2. Gera o token real de sessão dele
      token = Accounts.generate_user_session_token(free_user)

      # 3. Tenta acessar a rota VIP enviando o token no header (como um app Flutter faria)
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/pro/dashboard")

      # 4. A expectativa é ser barrado na porta pelo nosso Plug
      assert conn.status == 403
      assert json_response(conn, 403)["error"] =~ "Acesso negado"
    end

    test "Usuário PRO acessa a rota VIP com sucesso (200 OK)", %{conn: conn} do
      # 1. Cria o usuário
      {:ok, user} = Accounts.create_user(@pro_attrs)

      # 2. Faz o "upgrade" do plano direto no banco de dados (simulando um pagamento aprovado)
      {:ok, pro_user} = Finpes.Repo.update(Ecto.Changeset.change(user, plan_role: "pro"))

      # 3. Gera o token de sessão do usuário VIP
      token = Accounts.generate_user_session_token(pro_user)

      # 4. Acessa a rota VIP
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/pro/dashboard")

      # 5. A expectativa é passar e ver a mensagem de boas-vindas
      assert conn.status == 200
      assert json_response(conn, 200)["message"] =~ "Dashboard VIP"
    end

    test "Usuário NÃO LOGADO recebe 401 Unauthorized na rota VIP", %{conn: conn} do
      # Tenta acessar direto, sem mandar token nenhum
      conn = get(conn, "/api/pro/dashboard")

      # O primeiro Plug (ApiAuth) já deve barrar e nem deixar chegar no Plug de Planos
      assert conn.status == 401
      assert json_response(conn, 401)["error"] =~ "Não autorizado"
    end
  end
end
