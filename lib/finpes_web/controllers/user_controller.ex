defmodule FinpesWeb.UserController do
  use FinpesWeb, :controller
  alias Finpes.Accounts

  def me(conn, _params) do
    # O nosso Plug de autenticação colocou o ID do usuário validado aqui:
    user_id = conn.assigns[:current_user_id]

    # Busca o usuário no banco
    user = Accounts.get_user!(user_id)

    # Retorna os dados dele
    conn
    |> put_status(:ok)
    |> json(%{
      id: user.id,
      name: user.name,
      email: user.email,
      mensagem: "Parabéns! Você acessou uma rota protegida."
    })
  end

  @doc """
  Registra um novo usuário e já efetua o login automático.
  """
  def create(conn, %{"name" => name, "email" => email, "password" => password} = params) do
    # 1. Tenta criar o usuário no banco (Isso já vai rodar o hash do Argon2)
    case Accounts.create_user(%{name: name, email: email, password: password}) do
      {:ok, user} ->
        # 2. Se deu certo, gera o token de sessão
        token = Accounts.generate_user_session_token(user)

        # 3. Descobre quem chamou (web ou mobile) para devolver do jeito certo
        client_type = Map.get(params, "client_type", "web")

        # 4. Envia a resposta (vamos reaproveitar uma função privada parecida com a da sessão)
        send_auth_response(conn, user, token, client_type)

      {:error, %Ecto.Changeset{} = changeset} ->
        # 5. Se falhar (ex: email já existe, senha fraca), devolve os erros
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  # ---- FUNÇÕES PRIVADAS (Iguais às do SessionController) ----

  defp send_auth_response(conn, user, token, "web") do
    conn
    |> put_resp_cookie("api_auth_token", token,
      sign: false, http_only: true, secure: false, same_site: "Lax", max_age: 2_592_000
    )
    |> put_status(:created) # 201 Created
    |> json(%{
      message: "Conta criada com sucesso.",
      user: %{id: user.id, name: user.name, email: user.email, plan: user.plan_role}
    })
  end

  defp send_auth_response(conn, user, token, "mobile") do
    conn
    |> put_status(:created) # 201 Created
    |> json(%{
      message: "Conta criada com sucesso.",
      token: token,
      user: %{id: user.id, name: user.name, email: user.email, plan: user.plan_role}
    })
  end

  # Função auxiliar para formatar os erros do Ecto Changeset de forma amigável para o React/Flutter
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc """
  Rota de teste exclusiva para usuários do plano PRO.
  """
  def premium_dashboard(conn, _params) do
    # Se chegou aqui, é porque passou pelos DOIS Plugs!
    conn
    |> put_status(:ok)
    |> json(%{message: "Bem-vindo ao Dashboard VIP do Finpes!"})
  end
end
