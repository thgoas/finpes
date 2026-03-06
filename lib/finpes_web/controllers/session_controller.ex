defmodule FinpesWeb.SessionController do
  use FinpesWeb, :controller
  alias Finpes.Accounts

  @doc """
  Ação de Login.
  Recebe email, password e client_type ("web" ou "mobile").
  """
  def create(conn, %{"email" => email, "password" => password, "client_type" => client_type}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # 1. Gera o token e salva no banco
        token = Accounts.generate_user_session_token(user)

        # 2. Devolve a resposta formata para React ou Flutter
        send_auth_response(conn, user, token, client_type)

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "E-mail ou senha incorretos."})
    end
  end

  # Um fallback (plano B) caso o frontend esqueça de mandar o client_type,
  # assumimos que é "web" por padrão.
  def create(conn, %{"email" => email, "password" => password}) do
    create(conn, %{"email" => email, "password" => password, "client_type" => "web"})
  end

  @doc """
  Ação de Logout.
  """
  def delete(conn, _params) do
    # O nosso Plug `ApiAuth` colocou o token aqui quando autorizou a requisição!
    token = conn.assigns[:session_token]

    if token do
      Accounts.delete_session_token(token)
    end

    conn
    # Limpa o cookie do navegador (útil para o React)
    |> delete_resp_cookie("api_finpes_token")
    |> json(%{message: "Logout efetuado com sucesso."})
  end

  # ---- FUNÇÕES PRIVADAS DE RESPOSTA ----

  # Resposta para WEB (React): Envia Cookie HttpOnly e não manda o token no JSON
  defp send_auth_response(conn, user, token, "web") do
    conn
    |> put_resp_cookie("api_finpes_token", token,
      sign: false,
      http_only: true,
      secure: false,    # Mude para `true` quando for para Produção com HTTPS!
      same_site: "Lax", # Lax é o melhor para ambiente de desenvolvimento local (localhost)
      max_age: 2_592_000 # 30 dias
    )
    |> json(%{
      message: "Login efetuado com sucesso. (Cookie configurado!)",
      user: %{id: user.id, name: user.name, email: user.email, avatar_url: user.avatar_url}
    })
  end

  # Resposta para MOBILE (Flutter): Não manda Cookie, manda o Token no corpo do JSON
  defp send_auth_response(conn, user, token, "mobile") do
    conn
    |> json(%{
      message: "Login efetuado com sucesso.",
      token: token, # O Flutter vai pegar isso e salvar no Secure Storage
      user: %{id: user.id, name: user.name, email: user.email, avatar_url: user.avatar_url}
    })
  end
end
