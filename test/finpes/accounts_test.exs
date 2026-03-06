defmodule Finpes.AccountsTest do
  use Finpes.DataCase

  alias Finpes.Accounts
  # alias Finpes.Accounts.User

  # Dados válidos para criar um usuário de teste
  @valid_attrs %{name: "Thiago", email: "teste@teste.com", password: "Senha@123"}

  # Função auxiliar para criar o usuário antes dos testes
  def user_fixture() do
    {:ok, user} = Accounts.create_user(@valid_attrs)
    user
  end

  describe "Autenticação e Senhas" do
    setup do
      %{user: user_fixture()}
    end

    test "authenticate_user/2 retorna o usuário com credenciais válidas", %{user: user} do
      assert {:ok, authenticated_user} = Accounts.authenticate_user(user.email, "Senha@123")
      assert authenticated_user.id == user.id
    end

    test "authenticate_user/2 retorna erro com senha inválida", %{user: user} do
      assert {:error, :unauthorized} = Accounts.authenticate_user(user.email, "SenhaErrada@123")
    end

    test "authenticate_user/2 retorna erro se o usuário não existir" do
      assert {:error, :not_found} = Accounts.authenticate_user("naoexiste@teste.com", "Senha@123")
    end
  end

  describe "Gerenciamento de Tokens" do
    setup do
      %{user: user_fixture()}
    end

    test "gera, verifica e deleta o token de sessão com sucesso", %{user: user} do
      # 1. Gera o token
      token = Accounts.generate_user_session_token(user)
      assert is_binary(token)

      # 2. Verifica se o token é válido e pertence ao usuário
      assert {:ok, user_id} = Accounts.verify_session_token(token)
      assert user_id == user.id

      # 3. Faz o logout (deleta o token)
      Accounts.delete_session_token(token)

      # 4. Verifica se o token foi realmente revogado
      assert {:error, :revoked} = Accounts.verify_session_token(token)
    end
  end
end
