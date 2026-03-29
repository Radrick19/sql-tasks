-- База данных 1. Транспортные средства

--Задача 1
-- Найдите производителей (maker) и модели всех мотоциклов, которые имеют мощность более 150 лошадиных сил, стоят менее 20 тысяч долларов и являются спортивными (тип Sport).
-- Также отсортируйте результаты по мощности в порядке убывания.
-- Решение:
SELECT v.maker, v.model 
FROM motorcycle m
INNER JOIN vehicle v ON m.model = v.model 
WHERE m.horsepower > 150 AND m.price < 20000 AND m."type" = 'Sport'
ORDER BY m.horsepower DESC

-- Задача 2
-- Найти информацию о производителях и моделях различных типов транспортных средств (автомобили, мотоциклы и велосипеды), которые соответствуют заданным критериям.
-- Решение:
SELECT 
    v.maker,
    v.model,
    c.horsepower,
    c.engine_capacity,
    v."type" 
FROM vehicle v
JOIN car c 
    ON c.model = v.model
WHERE c.horsepower > 150
  AND c.engine_capacity < 3
  AND c.price < 35000

UNION ALL

SELECT 
    v.maker,
    v.model,
    m.horsepower,
    m.engine_capacity,
    v."type" 
FROM vehicle v
JOIN motorcycle m 
    ON m.model = v.model
WHERE m.horsepower > 150
  AND m.engine_capacity < 1.5
  AND m.price < 20000

UNION ALL

SELECT 
    v.maker,
    v.model,
    NULL AS horsepower,
    NULL AS engine_capacity,
    v."type" 
FROM vehicle v
JOIN bicycle b 
    ON b.model = v.model
WHERE b.gear_count > 18
  AND b.price < 4000

ORDER BY horsepower DESC NULLS LAST

-- Использован UNION ALL, потому что данные берутся из разных таблиц с разными условиями, и так проще собрать их в один результат без лишних JOIN. 
-- Кроме того, не требуется удаление дубликатов, поэтому UNION ALL работает быстрее и логически подходит лучше