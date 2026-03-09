defmodule FinpesWeb.Plugs.RequirePlanTest do
  use FinpesWeb.ConnCase

  alias Finpes.Accounts
  alias FinpesWeb.Plugs.RequirePlan

  # Usuário padrão (Free)
  @free_user_attrs %{
    "name" => "Usuário Free",
    "email" => "free@finpes.com",
    "password" => "Senha@123"
  }

  # Usuário Pro
  @pro_user_attrs %{
    "name" => "Usuário Pro",
    "email" => "pro@finpes.com",
    "password" => "Senha@123"
  }

  setup %{conn: conn} do
    # O Phoenix Controller/Plug precisa do parser de JSON ativado para usar a função `json/2` no erro
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> fetch_query_params()

    %{conn: conn}
  end

  describe "RequirePlan Plug" do
    test "Bloqueia (403 Forbidden) usuário Free tentando acessar rota Pro", %{conn: conn} do
      {:ok, free_user} = Accounts.create_user(@free_user_attrs)

      # 1. Simulamos que o usuário Free já passou pelo Plug de Autenticação
      conn_autenticada = assign(conn, :current_user_id, free_user.id)

      # 2. Passamos a conexão pelo nosso Plug exigindo o plano "pro"
      conn_bloqueada = RequirePlan.call(conn_autenticada, ["pro"])

      # 3. Verificamos se ele foi barrado corretamente
      assert conn_bloqueada.status == 403
      assert json_response(conn_bloqueada, 403)["error"] =~ "Acesso negado"

      # Verifica se o Plug interrompeu o fluxo (não deixaria chegar no Controller)
      assert conn_bloqueada.halted == true
    end

    test "Permite a passagem de um usuário com o plano exigido (Pro)", %{conn: conn} do
      {:ok, pro_user} = Accounts.create_user(@pro_user_attrs)

      # Como não temos uma função no Controller para atualizar o plano ainda,
      # vamos simular a atualização direto no banco para o teste
      {:ok, pro_user} = Finpes.Repo.update(Ecto.Changeset.change(pro_user, plan_role: "pro"))

      # 1. Simulamos o usuário logado
      conn_autenticada = assign(conn, :current_user_id, pro_user.id)

      # 2. Passamos a conexão pelo Plug exigindo o plano "pro"
      conn_liberada = RequirePlan.call(conn_autenticada, ["pro"])

      # 3. Verificamos se ele passou com sucesso
      refute conn_liberada.halted

      # Verifica se o Plug teve a gentileza de deixar o struct do usuário na conexão
      assert conn_liberada.assigns[:current_user].id == pro_user.id
      assert conn_liberada.assigns[:current_user].plan_role == "pro"
    end

    test "Bloqueia (401 Unauthorized) se não houver usuário logado", %{conn: conn} do
      # Passamos a conexão crua (sem o assign :current_user_id)
      conn_barrada = RequirePlan.call(conn, ["pro"])

      assert conn_barrada.status == 401
      assert json_response(conn_barrada, 401)["error"] =~ "Não autorizado"
      assert conn_barrada.halted == true
    end
  end
end
