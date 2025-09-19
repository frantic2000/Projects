/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Потапов Роман
 * Дата: 21.06.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT COUNT(id) AS users_count,
		SUM(payer) AS payer_users,
		ROUND(AVG(payer), 2) AS avg_payer_users
FROM fantasy.users


-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT race, 
	COUNT(id) AS users_count,
	SUM(payer) AS payer_users,
	ROUND(AVG(payer), 2) AS avg_payer_users
FROM fantasy.users JOIN fantasy.race USING(race_id)
GROUP BY race

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:

SELECT COUNT(amount) AS count_amount,
		SUM(amount) AS sum_amount,
		MIN(amount) AS min_amount,
		MAX(amount) AS max_amount,
		ROUND(AVG(amount::INT), 2) AS avg_amount,
		PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY amount) AS med_amount,
		STDDEV(amount) AS stand_dev_amount
FROM fantasy.events

UNION

SELECT COUNT(amount) AS count_amount,
		SUM(amount) AS sum_amount,
		MIN(amount) AS min_amount,
		MAX(amount) AS max_amount,
		ROUND(AVG(amount::INT), 2) AS avg_amount,
		PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY amount) AS med_amount,
		STDDEV(amount) AS stand_dev_amount
FROM fantasy.events
WHERE amount<>0
-- 2.2: Аномальные нулевые покупки:
SELECT COUNT(transaction_id) AS count_pay,
       COUNT(CASE WHEN amount = 0 THEN transaction_id END) AS count_null_pay,
       COUNT(CASE WHEN amount = 0 THEN transaction_id END)::FLOAT / COUNT(transaction_id) AS percent_pay
FROM fantasy.events e

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
WITH amount AS(
	SELECT e.id, 
	SUM(AMOUNT) AS sum_amount,
	COUNT(e.transaction_id) AS transaction_count
	FROM fantasy.events e 
	GROUP BY e.id 
)
SELECT CASE
		WHEN u.payer = 1 THEN 'платящий'
		ELSE 'неплатящий'
END AS players, 
		COUNT(DISTINCT u.id) AS players_count,
		ROUND(AVG(COALESCE(a.transaction_count::INT, 0)), 2) AS avg_transactions_per_player,
		ROUND(AVG(COALESCE(a.sum_amount::INT, 0)), 2) AS avg_amount_per_player
FROM fantasy.users AS u JOIN amount AS a using(id)
GROUP BY players 
		


-- 2.4: Популярные эпические предметы:
SELECT game_items, 
		COUNT(transaction_id) AS transaction_count_absolute, 
		COUNT(transaction_id)::REAL / (SELECT count(transaction_id) FROM fantasy.events WHERE amount <> 0) AS transaction_count_relatively,
		COUNT(DISTINCT e.id)::REAL/ (SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount <> 0) AS users_count
FROM fantasy.events AS e RIGHT JOIN fantasy.items AS i using(item_code)
WHERE amount <> 0
GROUP BY game_items 
ORDER BY transaction_count_absolute desc
-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
WITH total_players AS(
	SELECT race_id, 
	COUNT(id) AS total_players
	FROM fantasy.users
	GROUP BY race_id
),
buyer_players AS(
	SELECT race_id,
	COUNT(DISTINCT id) AS buyer_players
	FROM fantasy.events AS e JOIN fantasy.users AS u USING(id)
	WHERE amount <> 0 
	GROUP BY race_id
),
payer_players AS(
	SELECT race_id,
	COUNT(DISTINCT id) AS payer_players
	FROM fantasy.users u JOIN fantasy.events e using(id)
	WHERE payer = 1 AND amount <> 0
	GROUP BY race_id
),
transaction_activity AS(
	SELECT race_id,
	COUNT(transaction_id) AS total_transaction,
		SUM(amount) AS total_amount
		FROM fantasy.events AS e JOIN fantasy.users u USING(id) 
	WHERE amount <> 0
	GROUP BY u.race_id
)
SELECT tp.race_id, -- Идентификатор расы
		tp.total_players, -- Общее количество зарегистрированных игроков
		bp.buyer_players, -- Количество игроков, совершивших покупку
		ROUND(bp.buyer_players * 100.0 / tp.total_players, 2) AS buyer_players_share, -- Процент игроков, совершивших покупку
		p.payer_players, -- Количество платящих игроков
		ROUND(p.payer_players * 100.0 / bp.buyer_players, 2) AS payer_players_share, -- Процент платящих игроков среди совершавших покупку
		ROUND(total_transaction / buyer_players, 2) AS avg_total_transaction_per_user, -- Среднее количество покупок на одного игрока
		ROUND(total_amount::int / total_transaction, 2) AS avg_transaction_amount,  -- Средняя стоимость одной покупки
		ROUND(total_amount::int / buyer_players, 2) AS avg_total_amount_per_user -- Средняя суммарная стоимость всех покупок на одного игрока
		FROM total_players AS tp JOIN buyer_players AS bp using(race_id)
			JOIN payer_players AS p USING(race_id)
			JOIN transaction_activity AS ta USING(race_id)
ORDER BY tp.race_id