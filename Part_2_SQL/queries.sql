-- 1. Простая выборка. Клиенты из Новосибирска, зарегистрированные в 2025 году, по дате регистрации.
SELECT 
    client_id, 
    full_name, 
    registered_at
FROM clients
WHERE city = 'Новосибирск' 
  AND EXTRACT(YEAR FROM registered_at) = 2025
ORDER BY registered_at ASC;

-- 2. Агрегация. Количество открытых счетов в каждой валюте.
-- Считаем только те счета, которые еще не закрыты (closed_at IS NULL).
SELECT 
    currency, 
    COUNT(account_id) AS open_accounts_count
FROM accounts
WHERE closed_at IS NULL
GROUP BY currency;

-- 3. JOIN и агрегация. Имя клиента и общая сумма входящих транзакций.
-- Используем LEFT JOIN, чтобы в выборку попали даже клиенты без транзакций (у них сумма будет NULL или 0).
SELECT 
    c.full_name, 
    COALESCE(SUM(t.amount), 0) AS total_incoming_amount
FROM clients c
LEFT JOIN accounts a ON c.client_id = a.client_id
LEFT JOIN transactions t ON a.account_id = t.account_id AND t.tx_type = 'in'
GROUP BY c.client_id, c.full_name;

-- 4. Анти-джойн. Клиенты без единого счёта.
-- Вариант 1: через LEFT JOIN (обычно самый быстрый).
SELECT 
    c.client_id, 
    c.full_name
FROM clients c
LEFT JOIN accounts a ON c.client_id = a.client_id
WHERE a.account_id IS NULL;

-- Вариант 2: через NOT EXISTS (тоже хорошая практика).
-- SELECT client_id, full_name FROM clients c 
-- WHERE NOT EXISTS (SELECT 1 FROM accounts a WHERE a.client_id = c.client_id);

-- 5. HAVING. Клиенты, у которых больше двух счетов.
SELECT 
    c.client_id, 
    c.full_name, 
    COUNT(a.account_id) AS total_accounts
FROM clients c
JOIN accounts a ON c.client_id = a.client_id
GROUP BY c.client_id, c.full_name
HAVING COUNT(a.account_id) > 2;

-- 6. Дубли. Найти задвоенные транзакции (одинаковые account_id, tx_date, amount).
-- Группируем по трем полям и ищем те группы, где количество записей больше 1.
SELECT 
    account_id, 
    tx_date, 
    amount, 
    COUNT(*) AS duplicate_count
FROM transactions
GROUP BY account_id, tx_date, amount
HAVING COUNT(*) > 1;

-- 7. Со звёздочкой: оконные функции. Топ-3 клиентов по сумме исходящих транзакций в каждом месяце.
-- Сначала суммируем траты по клиентам и месяцам, затем через оконную функцию присваиваем рейтинг.
WITH client_monthly_out AS (
    SELECT 
        c.client_id,
        c.full_name,
        DATE_TRUNC('month', t.tx_date) AS tx_month,
        SUM(t.amount) AS total_out
    FROM clients c
    JOIN accounts a ON c.client_id = a.client_id
    JOIN transactions t ON a.account_id = t.account_id
    WHERE t.tx_type = 'out'
    GROUP BY c.client_id, c.full_name, DATE_TRUNC('month', t.tx_date)
),
ranked_clients AS (
    SELECT 
        full_name,
        tx_month,
        total_out,
        ROW_NUMBER() OVER (PARTITION BY tx_month ORDER BY total_out DESC) as rank
    FROM client_monthly_out
)
SELECT 
    tx_month,
    full_name,
    total_out,
    rank
FROM ranked_clients
WHERE rank <= 3
ORDER BY tx_month DESC, rank ASC;
