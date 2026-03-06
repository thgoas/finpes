defmodule FinpesWeb.Plugs.Finpes do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]
  alias Finpes.Accounts

  # init/1 é obrigatório em Plugs de módulo, mas não precisamos fazer nada nele
  def init(opts), do: opts

  # call/2 é onde a mágica acontece em cada requisição
  def call(conn, _opts) do
    with {:ok, token} <- extract_token(conn),
         {:ok, user_id} <- Accounts.verify_session_token(token) do

      # Sucesso! Colocamos o ID do usuário e o token na conexão
      # para podermos usá-los lá nos nossos Controllers
      conn
      |> assign(:current_user_id, user_id)
      |> assign(:session_token, token)
    else
      _ ->
        # Falhou na extração ou na verificação
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Não autorizado. Faça login novamente."})
        |> halt() # Interrompe o pipeline, não deixa chegar no Controller
    end
  end

  # Tenta extrair o token do Header (padrão do Mobile/Flutter)
  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> extract_token_from_cookie(conn)
    end
  end

  # Se não achou no Header, tenta no Cookie (padrão da Web/React)
  defp extract_token_from_cookie(conn) do
    # O fetch_cookies/1 garante que a conexão leu os cookies da requisição
    conn = fetch_cookies(conn)

    case conn.cookies["api_finpes_token"] do
      nil -> {:error, :missing_token}
      token -> {:ok, token}
    end
  end
end
