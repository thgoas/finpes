# 📖 Finpes API Documentation

## 🔒 Base & Autenticação
* **Base URL:** `/api`
* **Content-Type:** `application/json`
* **Autenticação:** Todas as rotas (exceto login/cadastro) exigem o Header de autorização: `Authorization: Bearer <seu_token_aqui>`

---

## 🧩 Padrão de Respostas

**Sucesso (200 OK / 201 Created):**

    {
      "message": "Mensagem opcional de sucesso",
      "data": { "id": "uuid", "..." : "..." }
    }

**Erro de Validação (422 Unprocessable Entity):**

    {
      "errors": {
        "campo": ["motivo do erro"],
        "amount": ["O valor deve ser maior que zero (em centavos)"]
      }
    }

---

## 🧑‍💻 1. Usuário Autenticado (Me)

### `GET /api/me`
* **Descrição:** Retorna os dados do usuário logado atualmente.
* **Response Exemplo:**

    {
      "data": {
        "id": "uuid",
        "name": "Thiago",
        "email": "thiago@email.com"
      }
    }

### `DELETE /api/logout`
* **Descrição:** Invalida o token atual e desloga o usuário da sessão.

---

## 💳 2. Carteiras (Wallets)
As carteiras representam os locais físicos ou virtuais onde o dinheiro está guardado.

* **Endpoints:**
  * `GET /api/wallets` - Lista todas as carteiras do usuário.
  * `POST /api/wallets` - Cria uma nova carteira.
  * `GET /api/wallets/:id` - Busca detalhes de uma carteira específica.
  * `PUT /api/wallets/:id` - Atualiza os dados de uma carteira.
  * `DELETE /api/wallets/:id` - Exclui uma carteira.

* **Payload de Envio (POST / PUT):**

    {
      "name": "Nubank",
      "type": "credit_card", 
      "initial_balance": 0,  
      "color": "#8A05BE",    
      "icon": "credit-card"  
    }

* **Notas dos Campos:**
  * `type` (Obrigatório): Deve ser `"checking"`, `"savings"`, `"credit_card"` ou `"cash"`.
  * `initial_balance` (Obrigatório): Deve ser um Inteiro, em CENTAVOS (Ex: R$ 150,50 = 15050). Padrão é 0.

---

## 🏷️ 3. Categorias (Categories)
Usadas para classificar as transações e montar o gráfico de saúde financeira (Regra 50/30/20).

* **Endpoints:**
  * `GET /api/categories` - Lista todas as categorias.
  * `POST /api/categories` - Cria uma nova categoria.
  * `GET /api/categories/:id` - Busca detalhes de uma categoria.
  * `PUT /api/categories/:id` - Atualiza uma categoria.
  * `DELETE /api/categories/:id` - Exclui uma categoria.

* **Payload de Envio (POST / PUT):**

    {
      "name": "Mercado",
      "type": "expense",             
      "classification": "essential", 
      "color": "#EF4444",            
      "icon": "shopping-cart"        
    }

* **Notas dos Campos:**
  * `type` (Obrigatório): Deve ser `"income"` ou `"expense"`.
  * `classification` (Obrigatório): Deve ser `"essential"`, `"optional"` ou `"savings"`.

---

## 💸 4. Transações (Transactions)
O coração do sistema. Representa as movimentações de entrada, saída e transferências entre contas.

* **Endpoints:**
  * `GET /api/transactions` - Lista as transações do usuário.
  * `POST /api/transactions` - Cria uma nova transação.
  * `GET /api/transactions/:id` - Busca detalhes da transação.
  * `PUT /api/transactions/:id` - Atualiza a transação.
  * `DELETE /api/transactions/:id` - Exclui a transação.

* **Payload de Envio (POST / PUT):**

    {
      "description": "Compra no Mercado",
      "amount": 15000,                  
      "type": "expense",                
      "status": "paid",                 
      "expected_date": "2026-03-12",    
      "paid_date": "2026-03-12",        
      "ignore_in_reports": false,       
      "wallet_id": "uuid-da-carteira",  
      "category_id": "uuid-da-categoria",
      "installment": "1/10",            
      "recurrence_group_id": null,      
      "transfer_id": null               
    }

* **Notas dos Campos:**
  * `amount` (Obrigatório): Inteiro e POSITIVO, em CENTAVOS (Ex: R$ 150,00 = 15000).
  * `type` (Obrigatório): Deve ser `"income"`, `"expense"` ou `"transfer"`.
  * `status` (Obrigatório): Deve ser `"pending"` ou `"paid"`.
  * `expected_date` (Obrigatório): Formato ISO 8601 `"YYYY-MM-DD"`.
  * `wallet_id` (Obrigatório): Deve ser o ID válido de uma carteira pertencente ao usuário.
  * `ignore_in_reports` (Opcional): Booleano (`true`/`false`). Padrão é `false`. Útil para não contabilizar compras feitas para terceiros nos gráficos.