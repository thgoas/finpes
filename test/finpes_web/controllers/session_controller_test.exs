defmodule FinpesWeb.SessionControllerTest do
  use FinpesWeb.ConnCase

  alias Finpes.Accounts

  @valid_attrs %{name: "Thiago", email: "teste@teste.com", password: "Senha@123"}

  setup %{conn: conn} do
    {:ok, user} = Accounts.create_user(@valid_attrs)
    # Retornamos a conexão e o usuário para os testes usarem
    %{conn: conn |> put_req_header("accept", "application/json"), user: user}
  end

  describe "POST /api/login" do
    test "Login WEB retorna Cookie HttpOnly", %{conn: conn, user: user} do
      conn = post(conn, "/api/login", %{
        "email" => user.email,
        "password" => "Senha@123",
        "client_type" => "web"
      })

      # Verifica se retornou status 200
      assert json_response(conn, 200)["message"] =~ "Cookie configurado"

      # Verifica se o cookie foi setado na resposta
      assert conn.resp_cookies["api_finpes_token"]
      assert conn.resp_cookies["api_finpes_token"].http_only == true
    end

    test "Login MOBILE retorna o Token no corpo do JSON", %{conn: conn, user: user} do
      conn = post(conn, "/api/login", %{
        "email" => user.email,
        "password" => "Senha@123",
        "client_type" => "mobile"
      })

      resposta = json_response(conn, 200)
      assert resposta["token"] != nil

      # Garante que NENHUM cookie foi enviado para o mobile
      refute conn.resp_cookies["api_finpes_token"]
    end
  end

  describe "Rotas Protegidas e Logout" do
    test "Acessa rota /api/me usando Cookie (WEB)", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_cookie("api_finpes_token", token) # Simula o navegador enviando o cookie
        |> get("/api/me")

      assert json_response(conn, 200)["email"] == user.email
    end

    test "Acessa rota /api/me usando Header Bearer (MOBILE)", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}") # Simula o Flutter enviando o header
        |> get("/api/me")

      assert json_response(conn, 200)["email"] == user.email
    end

    test "Falha ao acessar /api/me sem credenciais", %{conn: conn} do
      conn = get(conn, "/api/me")
      assert json_response(conn, 401)["error"] == "Não autorizado. Faça login novamente."
    end

    test "Logout revoga o token com sucesso", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user)

      # Faz o logout usando o header Bearer
      conn_logout =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/logout")

      assert json_response(conn_logout, 200)["message"] =~ "Logout efetuado"

      # Tenta acessar a rota protegida com o MESMO token após o logout
      conn_tentativa =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/me")

      assert json_response(conn_tentativa, 401)
    end
  end
end
