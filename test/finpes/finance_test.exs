defmodule Finpes.FinanceTest do
  use Finpes.DataCase

  alias Finpes.Finance
  alias Finpes.Finance.Wallet
  alias Finpes.Accounts
  alias Finpes.Finance.Category
  alias Finpes.Finance.Transaction

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
  describe "categories (Categorias)" do
    @valid_category_attrs %{name: "Mercado", type: "expense", classification: "essential", color: "#FF0000", icon: "shopping-cart"}
    # @update_category_attrs %{name: "Cinema", type: "expense", classification: "optional"}
    @invalid_category_attrs %{name: nil, type: "investimento", classification: "nenhuma"}

    def category_fixture(user_id, attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_category_attrs)
        |> then(&Finance.create_user_category(user_id, &1))
      category
    end

    test "list_user_categories/1 retorna APENAS as categorias do usuário" do
      user1 = user_fixture()
      user2 = user_fixture(@hacker_user_attrs)

      cat1 = category_fixture(user1.id)
      _cat2 = category_fixture(user2.id, %{name: "Categoria do Hacker"})

      categories = Finance.list_user_categories(user1.id)
      assert length(categories) == 1
      assert hd(categories).id == cat1.id
    end

    test "get_user_category!/2 levanta erro se tentar acessar categoria de outro" do
      user = user_fixture()
      hacker = user_fixture(@hacker_user_attrs)
      cat = category_fixture(user.id)

      assert_raise Ecto.NoResultsError, fn ->
        Finance.get_user_category!(hacker.id, cat.id)
      end
    end

    test "create_user_category/2 com dados válidos" do
      user = user_fixture()
      assert {:ok, %Category{} = cat} = Finance.create_user_category(user.id, @valid_category_attrs)
      assert cat.classification == "essential"
      assert cat.type == "expense"
    end

    test "create_user_category/2 barra tipos e classificações inválidas" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Finance.create_user_category(user.id, @invalid_category_attrs)
    end
  end

  describe "transactions (Transações)" do
    @valid_transaction_attrs %{
      description: "Compra no Mercado",
      amount: 15000, # R$ 150,00
      type: "expense",
      status: "paid",
      expected_date: ~D[2026-03-12],
      paid_date: ~D[2026-03-12],
      ignore_in_reports: false
    }

    @update_transaction_attrs %{
      description: "Compra no Mercado Atualizada",
      amount: 16000,
      status: "pending"
    }

    @invalid_transaction_attrs %{
      description: nil,
      amount: -50, # Inválido: não pode ser negativo
      type: "crypto", # Inválido
      status: "atrasado" # Inválido
    }

    # Helper para criar toda a cadeia necessária para uma transação
    def transaction_fixture(user_id, wallet_id, category_id \\ nil, attrs \\ %{}) do
      final_attrs =
        @valid_transaction_attrs
        |> Enum.into(attrs)
        |> Map.put(:wallet_id, wallet_id)
        |> Map.put(:category_id, category_id)

      {:ok, transaction} = Finance.create_user_transaction(user_id, final_attrs)
      transaction
    end

    test "list_user_transactions/1 retorna APENAS as transações do usuário" do
      user = user_fixture()
      wallet = wallet_fixture(user.id)
      category = category_fixture(user.id)

      hacker = user_fixture(@hacker_user_attrs)
      hacker_wallet = wallet_fixture(hacker.id, %{name: "Hacker Wallet"})

      t1 = transaction_fixture(user.id, wallet.id, category.id)
      _t2 = transaction_fixture(hacker.id, hacker_wallet.id)

      transactions = Finance.list_user_transactions(user.id)
      assert length(transactions) == 1
      assert hd(transactions).id == t1.id
    end

    test "create_user_transaction/2 barra a criação se o usuário tentar usar a carteira de outro (Tenant Isolation)" do
      user = user_fixture()
      hacker = user_fixture(@hacker_user_attrs)
      carteira_do_hacker = wallet_fixture(hacker.id, %{name: "Hacker Wallet"})

      # O usuário tenta criar uma transação usando o ID da carteira do hacker
      assert_raise Ecto.NoResultsError, fn ->
        payload = Map.put(@valid_transaction_attrs, :wallet_id, carteira_do_hacker.id)
        Finance.create_user_transaction(user.id, payload)
      end
    end

    test "create_user_transaction/2 com dados válidos" do
      user = user_fixture()
      wallet = wallet_fixture(user.id)

      payload = Map.put(@valid_transaction_attrs, :wallet_id, wallet.id)
      assert {:ok, %Transaction{} = t} = Finance.create_user_transaction(user.id, payload)
      assert t.description == "Compra no Mercado"
      assert t.amount == 15000
    end

    test "create_user_transaction/2 barra valores negativos e tipos inválidos" do
      user = user_fixture()
      wallet = wallet_fixture(user.id)
      payload = Map.put(@invalid_transaction_attrs, :wallet_id, wallet.id)
      assert {:error, %Ecto.Changeset{}} = Finance.create_user_transaction(user.id, payload)
    end
    test "update_transaction/2 com dados válidos atualiza a transação" do
      user = user_fixture()
      wallet = wallet_fixture(user.id)
      transaction = transaction_fixture(user.id, wallet.id)

      assert {:ok, %Transaction{} = updated_t} = Finance.update_transaction(transaction, @update_transaction_attrs)
      assert updated_t.description == "Compra no Mercado Atualizada"
      assert updated_t.amount == 16000
      assert updated_t.status == "pending"
    end

    test "delete_transaction/1 apaga a transação do banco de dados" do
      user = user_fixture()
      wallet = wallet_fixture(user.id)
      transaction = transaction_fixture(user.id, wallet.id)

      assert {:ok, %Transaction{}} = Finance.delete_transaction(transaction)

      # Garante que a transação sumiu do banco
      assert_raise Ecto.NoResultsError, fn ->
        Finance.get_user_transaction!(user.id, transaction.id)
      end
    end
  end
end
