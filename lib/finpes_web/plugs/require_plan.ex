defmodule FinpesWeb.Plugs.RequirePlan do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]
  alias Finpes.Accounts

  @doc """
  O `init` recebe os planos permitidos que vamos definir lá no router.
  Ex: se passarmos :pro, ele transforma em ["pro"].
  """
  def init(allowed_plans) do
    # Garante que sempre teremos uma lista de strings
    allowed_plans |> List.wrap() |> Enum.map(&to_string/1)
  end

  @doc """
  O `call` é executado em cada requisição para as rotas protegidas por este Plug.
  """
  def call(conn, allowed_plans) do
    # Pegamos o ID do usuário que o nosso primeiro Plug (ApiAuth) validou e colocou na conexão
    user_id = conn.assigns[:current_user_id]

    if user_id do
      # Buscamos o usuário no banco para ver o status atualizado do plano dele
      user = Accounts.get_user!(user_id)

      if user.plan_role in allowed_plans do
        # Sucesso! O usuário tem o plano exigido.
        # Já deixamos o struct do usuário na conexão para o Controller não precisar buscar de novo.
        assign(conn, :current_user, user)
      else
        # Barrado! O usuário está logado, mas não tem o plano pago.
        # Retornamos 403 Forbidden (Proibido), diferente do 401 Unauthorized (Não logado).
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Acesso negado. Faça upgrade do seu plano para acessar este recurso."})
        |> halt()
      end
    else
      # Prevenção: Se por algum motivo este Plug for chamado sem o usuário estar logado
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Não autorizado."})
      |> halt()
    end
  end
end
