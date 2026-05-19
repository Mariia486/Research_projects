/* Проект: анализ данных для агентства недвижимости*/



-- Задача 1: Время активности объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l  
    FROM real_estate.flats     
)
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS (
    SELECT f.id  
    FROM real_estate.flats f  
    WHERE 
        f.total_area < (SELECT total_area_limit FROM limits)
        AND (f.rooms < (SELECT rooms_limit FROM limits) OR f.rooms IS NULL)
        AND (f.balcony < (SELECT balcony_limit FROM limits) OR f.balcony IS NULL)
        AND ((f.ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND f.ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR f.ceiling_height IS NULL)
), 
filtered_data AS (
    SELECT a.id,
           a.first_day_exposition,
           a.days_exposition,
           a.last_price,
           f.city_id,
           f.total_area,
           f.rooms,
           f.ceiling_height,
           f.floor,
           f.balcony  
    FROM real_estate.advertisement a  
    JOIN real_estate.flats f ON a.id = f.id  
    WHERE a.days_exposition >= 0 AND a.days_exposition <= 365  
      AND a.last_price > 1000 AND a.last_price < 100000000  
      AND f.id IN (SELECT id FROM filtered_id) 
)
-- Используйем id объявлений (СТЕ filtered_id), которые не содержат выбросы при анализе данных
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
    SELECT f.id  
    FROM real_estate.flats f  
    WHERE 
        f.total_area < (SELECT total_area_limit FROM limits)
        AND (f.rooms < (SELECT rooms_limit FROM limits) OR f.rooms IS NULL)
        AND (f.balcony < (SELECT balcony_limit FROM limits) OR f.balcony IS NULL)
        AND ((f.ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND f.ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR f.ceiling_height IS NULL)
), 
filtered_data AS (
    SELECT a.id,
           a.first_day_exposition,
           a.days_exposition,
           a.last_price,
           f.city_id,
           f.total_area,
           f.rooms,
           f.ceiling_height,
           f.floor,
           f.balcony  
    FROM real_estate.advertisement a  
    JOIN real_estate.flats f ON a.id = f.id  
    WHERE a.days_exposition >= 0 AND a.days_exposition <= 365  
      AND a.last_price > 1000 AND a.last_price < 100000000  
      AND f.id IN (SELECT id FROM filtered_id) 
), categorized_data AS (
    SELECT *,
           CASE  
               WHEN days_exposition BETWEEN 1 AND 30 THEN '1-30 days'
               WHEN days_exposition BETWEEN 31 AND 90 THEN '31-90 days'
               WHEN days_exposition BETWEEN 91 AND 180 THEN '91-180 days'
               WHEN days_exposition > 180 THEN '181+ days'
               ELSE 'non category'
           END AS activity_category,
           CASE  
               WHEN city_id = (SELECT city_id FROM real_estate.city WHERE city = 'Санкт-Петербург') THEN 'Санкт-Петербург'
               ELSE 'ЛенОбл'
           END AS region  
    FROM filtered_data  
) 
SELECT region AS регион,
       activity_category AS сегмент_активности,
       COUNT(*) AS колво_объявлений,
       AVG(last_price / total_area) AS стоим_кв_м,
       AVG(total_area) AS ср_площадь,
       AVG(rooms) AS ср_колво_комнат,
       AVG(balcony) AS ср_колво_балконов  
FROM categorized_data  
GROUP BY region, activity_category  
ORDER BY region, activity_category;


-- Задача 2: Сезонность объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l  
    FROM real_estate.flats     
)
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS (
    SELECT f.id  
    FROM real_estate.flats f  
    WHERE 
        f.total_area < (SELECT total_area_limit FROM limits)
        AND (f.rooms < (SELECT rooms_limit FROM limits) OR f.rooms IS NULL)
        AND (f.balcony < (SELECT balcony_limit FROM limits) OR f.balcony IS NULL)
        AND ((f.ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND f.ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR f.ceiling_height IS NULL)
),
filtered_data AS (
    SELECT a.id,
           a.first_day_exposition,
           a.days_exposition,
           a.last_price,
           f.city_id,
           f.total_area,
           f.rooms,
           f.ceiling_height  
    FROM real_estate.advertisement a  
    JOIN real_estate.flats f ON a.id = f.id  
    WHERE a.days_exposition >= 0 AND a.days_exposition <= 365  
      AND a.last_price > 1000 AND a.last_price < 100000000  
      AND f.id IN (SELECT id FROM filtered_id)
      AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018  
      AND f.city_id IS NOT NULL
-- Используем id объявлений (СТЕ filtered_id), которые не содержат выбросы при анализе данных
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
    SELECT f.id  
    FROM real_estate.flats f  
    WHERE 
        f.total_area < (SELECT total_area_limit FROM limits)
        AND (f.rooms < (SELECT rooms_limit FROM limits) OR f.rooms IS NULL)
        AND (f.balcony < (SELECT balcony_limit FROM limits) OR f.balcony IS NULL)
        AND ((f.ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND f.ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR f.ceiling_height IS NULL)
),
filtered_data AS (
    SELECT a.id,
           a.first_day_exposition,
           a.days_exposition,
           a.last_price,
           f.city_id,
           f.total_area,
           f.rooms,
           f.ceiling_height  
    FROM real_estate.advertisement a  
    JOIN real_estate.flats f ON a.id = f.id  
    WHERE a.days_exposition BETWEEN 0 AND 365  
      AND a.last_price > 1000 AND a.last_price < 100000000  
      AND f.id IN (SELECT id FROM filtered_id)
      AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018  
      AND f.city_id IS NOT NULL  
),
activity_months AS (
    SELECT 
        id,
        EXTRACT(MONTH FROM first_day_exposition) AS month_pub,
        EXTRACT(MONTH FROM (first_day_exposition + days_exposition * INTERVAL '1 day')) AS month_rem,
        last_price,
        total_area  
    FROM filtered_data  
),
pub_data AS (
    SELECT month_pub AS month, id, last_price, total_area  
    FROM activity_months  
    WHERE month_pub IS NOT NULL  
),
rem_data AS (
    SELECT month_rem AS month, id, last_price, total_area  
    FROM activity_months  
    WHERE month_rem IS NOT NULL  
),
pub_agg AS (
    SELECT  
        month,
        COUNT(DISTINCT id) AS total_listings_pub,
        AVG(last_price / total_area) AS avg_price_per_sqm_pub,
        AVG(total_area) AS avg_area_pub  
    FROM pub_data  
    GROUP BY month  
),
rem_agg AS (
    SELECT  
        month,
        COUNT(DISTINCT id) AS total_listings_rem,
        AVG(last_price / total_area) AS avg_price_per_sqm_rem,
        AVG(total_area) AS avg_area_rem  
    FROM rem_data  
    GROUP BY month  
)
SELECT  
    COALESCE(p.month, r.month) AS month,
    COALESCE(total_listings_pub, 0) AS total_listings_pub,
    COALESCE(total_listings_rem, 0) AS total_listings_rem,
    avg_price_per_sqm_pub,
    avg_price_per_sqm_rem,
    avg_area_pub,
    avg_area_rem  
FROM pub_agg p  
FULL OUTER JOIN rem_agg r ON p.month = r.month  
ORDER BY month;
