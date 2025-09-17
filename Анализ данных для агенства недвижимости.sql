--Задача 1


WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND (
            (ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits))
            OR ceiling_height IS NULL
        )
)
SELECT 
    CASE 
        WHEN city = 'Санкт-Петербург' THEN 'СПБ'
        ELSE 'Ленобласть'
    END AS Город,
    CASE
        WHEN days_exposition BETWEEN 0 AND 31 THEN 'Месяц'
        WHEN days_exposition BETWEEN 31 AND 91 THEN 'Квартал'
        WHEN days_exposition BETWEEN 91 AND 181 THEN 'Пол_года'
        WHEN days_exposition > 181 THEN 'Более_полугода'
    END AS Активность,
    COUNT(id) AS Количество_объявлений,
    ROUND(AVG(last_price / total_area)::numeric, 2) AS Средняя_стоимость_квм,
    ROUND(AVG(total_area)::numeric, 2) AS Средняя_площадь,
    PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) AS Медиана_комнат,
    PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS Медиана_балконов
FROM real_estate.advertisement a 
JOIN real_estate.flats f USING (id)
JOIN real_estate.city c USING (city_id)
WHERE 
    id IN (SELECT id FROM filtered_id) 
    AND a.days_exposition IS NOT NULL
GROUP BY Город, Активность
ORDER BY Город DESC, Количество_объявлений DESC;


--Задача 2

--- Определим аномальные */значения (выбросы) по значению перцентилей:]
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats as f
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
)
select COUNT(a.id) as Количество,
		extract('month' from a.first_day_exposition) as Месяц_подачи,
		ROUND(AVG(last_price/total_area)::NUMERIC, 2) as Средняя_стоимость_квм,
		ROUND(AVG(total_area)::numeric, 2) as Средняя_площадь
from real_estate.advertisement a join real_estate.flats f USING(id)
WHERE id IN (SELECT * FROM filtered_id)
group by Месяц_подачи


--- Определим аномальные */значения (выбросы) по значению перцентилей:]
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats as f
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
)
select COUNT(a.id) as Количество,
		extract('month' from a.first_day_exposition + a.days_exposition::INT) as Месяц_снятия,
		ROUND(AVG(last_price/total_area)::NUMERIC, 2) as Средняя_стоимость_квм,
		ROUND(AVG(total_area)::numeric, 2) as Средняя_площадь
from real_estate.advertisement a join real_estate.flats f USING(id)
WHERE id IN (SELECT * FROM filtered_id)
group by Месяц_снятия

--Задача 3

WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) 
        OR ceiling_height IS NULL)
)
SELECT 
    t.type,
    c.city,
    COUNT(*) AS Количество_объявлений,
    ROUND(COUNT(a.id)::numeric / (SELECT COUNT(*) FROM real_estate.advertisement 
                                WHERE days_exposition IS NOT NULL), 4) AS Доля_снятых_с_публикации,
    ROUND(AVG(last_price / total_area)::numeric, 2) AS Средняя_стоимость_квм,
    ROUND(AVG(total_area)::numeric, 2) AS Средняя_площадь,
    ROUND(AVG(days_exposition)::numeric, 2) AS Ср_продолжительность_публикации
FROM real_estate."type" t 
JOIN real_estate.flats f USING(type_id)
JOIN real_estate.advertisement a USING(id)
JOIN real_estate.city c USING(city_id)
WHERE 
    days_exposition IS NOT NULL 
    AND city <> 'Санкт-Петербург' 
    AND id IN (SELECT id FROM filtered_id)
GROUP BY t.type, c.city
HAVING COUNT(id) > 50
ORDER BY Количество_объявлений DESC
LIMIT 15;