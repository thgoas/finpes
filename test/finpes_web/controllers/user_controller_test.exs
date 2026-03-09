defmodule FinpesWeb.UserControllerTest do
  use FinpesWeb.ConnCase

  # alias Finpes.Accounts

  @valid_attrs %{
    "name" => "Thiago Finanças",
    "email" => "thiago@finpes.com",
    "password" => "SenhaForte@123"
  }

  @invalid_attrs %{
    "name" => "Th", # Inválido: menor que 3 caracteres
    "email" => "email-invalido", # Inválido: formato errado
    "password" => "fraca" # Inválido: não passa na Regex (sem maiúscula, número, especial)
  }

  setup %{conn: conn} do
    %{conn: conn |> put_req_header("accept", "application/json")}
  end

  describe "POST /api/register" do
    test "Registra usuário WEB com sucesso e retorna Cookie", %{conn: conn} do
      # Adicionamos o client_type web
      params = Map.put(@valid_attrs, "client_type", "web")

      conn = post(conn, "/api/register", params)

      assert json_response(conn, 201)["message"] =~ "Conta criada com sucesso"

      # Verifica se o usuário tem o plano "free" por padrão
      assert json_response(conn, 201)["user"]["plan"] == "free"

      # Verifica se o Cookie HttpOnly foi setado para o auto-login
      assert conn.resp_cookies["api_auth_token"]
      assert conn.resp_cookies["api_auth_token"].http_only == true
    end

    test "Registra usuário MOBILE com sucesso e retorna Token JSON", %{conn: conn} do
      params = Map.put(@valid_attrs, "client_type", "mobile")

      conn = post(conn, "/api/register", params)

      resposta = json_response(conn, 201)
      assert resposta["message"] =~ "Conta criada"
      assert resposta["token"] != nil # O Flutter precisa do token aqui!

      # Garante que não enviou Cookie
      refute conn.resp_cookies["api_auth_token"]
    end

    test "Retorna erros 422 (Unprocessable Entity) quando os dados são inválidos", %{conn: conn} do
      conn = post(conn, "/api/register", @invalid_attrs)

      erros = json_response(conn, 422)["errors"]
      assert erros["name"] == ["Nome deve ter pelo menos 3 caracteres."]
      assert String.equivalent?(List.first(erros["email"]), "Formato de email inválido.")
      assert erros["password"] == ["Senha deve conter pelos de 8 a 72 caracteres, Letras Maiúsculas, Minúsculas, Números e Caracteres Especiais."]
    end

    test "Retorna erro 422 quando o e-mail já existe", %{conn: conn} do
      # Cria o usuário a primeira vez
      post(conn, "/api/register", @valid_attrs)

      # Tenta criar DE NOVO com o mesmo e-mail
      conn_repetida = post(conn, "/api/register", @valid_attrs)

      erros = json_response(conn_repetida, 422)["errors"]
      assert String.equivalent?(List.first(erros["email"]), "Email já cadastrado.")
    end
  end

end
