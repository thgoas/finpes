defmodule Finpes.FinanceTest do
  use Finpes.DataCase

  alias Finpes.Finance
  alias Finpes.Finance.Wallet
  alias Finpes.Accounts

  describe "wallets (Carteiras)" do
    # Dados de usuários para testarmos o isolamento
    @valid_user_attrs %{name: "Thiago", email: "thiago.finance@teste.com", password: "SenhaForte@123"}
    @hacker_user_attrs %{name: "Hacker", email: "hacker@teste.com", password: "SenhaForte@123"}

    # Dados válidos e inválidos da Wallet
    @valid_attrs %{name: "Nubank", type: "credit_card", initial_balance: 10000, color: "#8A05BE", icon: "credit-card"}
    @update_attrs %{name: "Itaú", type: "checking", initial_balance: 15000, color: "#EC7000", icon: "bank"}
    @invalid_attrs %{name: nil, type: "crypto", initial_balance: 150.50}

    # Helpers para criar registros no banco rapidamente durante os testes
    def user_fixture(attrs \\ @valid_user_attrs) do
      {:ok, user} = Accounts.create_user(attrs)
      user
    end

    def wallet_fixture(user_id, attrs \\ %{}) do
      {:ok, wallet} =
        attrs
        |> Enum.into(@valid_attrs)
        |> then(&Finance.create_user_wallet(user_id, &1))
      wallet
    end

    test "list_user_wallets/1 retorna APENAS as carteiras do usuário especificado" do
      user1 = user_fixture()
      user2 = user_fixture(@hacker_user_attrs)

      wallet1 = wallet_fixture(user1.id)
      # Cria uma carteira para o usuário 2
      _wallet2 = wallet_fixture(user2.id, %{name: "Carteira do Hacker"})

      # A busca deve trazer apenas a carteira do user1
      wallets = Finance.list_user_wallets(user1.id)

      assert length(wallets) == 1
      assert hd(wallets).id == wallet1.id
      assert hd(wallets).user_id == user1.id
    end

    test "get_user_wallet!/2 retorna a carteira solicitada se pertencer ao usuário" do
      user = user_fixture()
      wallet = wallet_fixture(user.id)

      fetched_wallet = Finance.get_user_wallet!(user.id, wallet.id)
      assert fetched_wallet.id == wallet.id
    end

    test "get_user_wallet!/2 levanta erro (Ecto.NoResultsError) se tentar buscar carteira de OUTRO usuário" do
      user = user_fixture()
      hacker = user_fixture(@hacker_user_attrs)
      wallet_do_user = wallet_fixture(user.id)

      # Hacker tenta buscar a carteira do usuário pelo ID
      assert_raise Ecto.NoResultsError, fn ->
        Finance.get_user_wallet!(hacker.id, wallet_do_user.id)
      end
    end

    test "create_user_wallet/2 com dados válidos cria a carteira atrelada ao usuário" do
      user = user_fixture()

      assert {:ok, %Wallet{} = wallet} = Finance.create_user_wallet(user.id, @valid_attrs)
      assert wallet.name == "Nubank"
      assert wallet.type == "credit_card"
      assert wallet.initial_balance == 10000
      assert wallet.user_id == user.id
    end

    test "create_user_wallet/2 com dados inválidos retorna um Ecto.Changeset de erro" do
      user = user_fixture()

      assert {:error, %Ecto.Changeset{}} = Finance.create_user_wallet(user.id, @invalid_attrs)
    end

    test "update_wallet/2 com dados válidos atualiza a carteira" do
      user = user_fixture()
      wallet = wallet_fixture(user.id)

      assert {:ok, %Wallet{} = updated_wallet} = Finance.update_wallet(wallet, @update_attrs)
      assert updated_wallet.name == "Itaú"
      assert updated_wallet.type == "checking"
      assert updated_wallet.initial_balance == 15000
    end

    test "update_wallet/2 com dados inválidos não altera o banco" do
      user = user_fixture()
      wallet = wallet_fixture(user.id)

      assert {:error, %Ecto.Changeset{}} = Finance.update_wallet(wallet, @invalid_attrs)

      # Garante que o nome no banco continua o original ("Nubank") e não mudou
      assert Finance.get_user_wallet!(user.id, wallet.id).name == wallet.name
    end

    test "delete_wallet/1 apaga a carteira do banco de dados" do
      user = user_fixture()
      wallet = wallet_fixture(user.id)

      assert {:ok, %Wallet{}} = Finance.delete_wallet(wallet)

      assert_raise Ecto.NoResultsError, fn ->
        Finance.get_user_wallet!(user.id, wallet.id)
      end
    end
  end
end
