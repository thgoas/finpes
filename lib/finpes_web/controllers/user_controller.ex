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
end
