-- База данных 2 . Автомобильные гонки

-- Задача 1
-- Определить, какие автомобили из каждого класса имеют наименьшую среднюю позицию в гонках, и вывести информацию о каждом таком автомобиле для данного класса,
-- включая его класс, среднюю позицию и количество гонок, в которых он участвовал. Также отсортировать результаты по средней позиции.
-- Решение:

WITH car_stats AS (
    SELECT
        c.name as car_name,
        c.class as car_class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM Cars c
    JOIN Results r 
        ON r.car = c.name
    GROUP BY c.name, c.class
)
SELECT
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count
FROM car_stats cs
WHERE cs.average_position = (
    SELECT MIN(cs2.average_position)
    FROM car_stats cs2
    WHERE cs2.car_class = cs.car_class
)
ORDER BY cs.average_position ASC

-- Сначала считаем для каждой машины её среднюю позицию и количество гонок. Затем для каждой записи проверяем, является ли эта средняя позиция минимальной среди машин того же класса.
-- Так получаем лучшие машины в каждом классе без использования сложных оконных функций.

-- Задача 2
-- Определить автомобиль, который имеет наименьшую среднюю позицию в гонках среди всех автомобилей, и вывести информацию об этом автомобиле, включая его класс,
-- среднюю позицию, количество гонок, в которых он участвовал, и страну производства класса автомобиля. Если несколько автомобилей имеют одинаковую наименьшую среднюю позицию, 
-- выбрать один из них по алфавиту (по имени автомобиля).
-- Решение: 

WITH car_stats AS (
    SELECT
        c.name as car_name,
        c.class as car_class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count,
        cl.country as car_country
    FROM Cars c
    JOIN Results r 
        ON r.car = c.name
    JOIN Classes cl
        ON cl.class = c.class
    GROUP BY c.name, c.class, cl.country
)
SELECT
    car_name,
    car_class,
    average_position,
    race_count,
    car_country
FROM car_stats
ORDER BY average_position ASC, car_name ASC
LIMIT 1

-- сначала считаем среднюю позицию и количество гонок для каждой машины, добавляя страну через таблицу классов.
-- Затем просто сортируем все машины по средней позиции, а при равенстве — по имени, и берём первую строку.

-- Задача 3
-- Определить классы автомобилей, которые имеют наименьшую среднюю позицию в гонках, и вывести информацию о каждом автомобиле из этих классов, включая его имя, среднюю позицию,
-- количество гонок, в которых он участвовал, страну производства класса автомобиля, а также общее количество гонок, в которых участвовали автомобили этих классов.
-- Если несколько классов имеют одинаковую среднюю позицию, выбрать все из них.
-- Решение:

WITH car_stats AS (
    SELECT
        c.name AS car_name,
        c.class AS car_class,
        cl.country AS car_country,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM Cars c
    JOIN Results r
        ON r.car = c.name
    JOIN Classes cl
        ON cl.class = c.class
    GROUP BY c.name, c.class, cl.country
),
class_avg AS (
    SELECT
        car_class,
        AVG(average_position) AS class_average_position
    FROM car_stats
    GROUP BY car_class
),
best_classes AS (
    SELECT car_class
    FROM class_avg
    WHERE class_average_position = (
        SELECT MIN(class_average_position)
        FROM class_avg
    )
),
class_race_count AS (
    SELECT
        c.class AS car_class,
        COUNT(r.race) AS total_races
    FROM Cars c
    JOIN Results r
        ON r.car = c.name
    GROUP BY c.class
)
SELECT
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cs.car_country,
    crc.total_races
FROM car_stats cs 
JOIN best_classes bc
    ON bc.car_class = cs.car_class
JOIN class_race_count crc
    ON crc.car_class = cs.car_class
ORDER BY cs.average_position ASC, cs.car_name ASC;

-- сначала считается статистика по каждой машине, потом по этим данным находится средняя позиция для каждого класса.
-- После этого выбираются классы с минимальной средней позицией, и уже для них выводятся все машины.
-- Отдельно считается общее число гонок по каждому такому классу.

-- Задача 4
-- Определить, какие автомобили имеют среднюю позицию лучше (меньше) средней позиции всех автомобилей в своем классе 
-- (то есть автомобилей в классе должно быть минимум два, чтобы выбрать один из них). 
-- Вывести информацию об этих автомобилях, включая их имя, класс, среднюю позицию, количество гонок, в которых они участвовали, и страну производства класса автомобиля. 
-- Также отсортировать результаты по классу и затем по средней позиции в порядке возрастания.
-- Решение:

WITH car_stats AS (
    SELECT
        c.name AS car_name,
        c.class AS car_class,
        cl.country AS car_country,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM Cars c
    JOIN Results r
        ON r.car = c.name
    JOIN Classes cl
        ON cl.class = c.class
    GROUP BY c.name, c.class, cl.country
),
class_stats AS (
    SELECT
        car_class,
        AVG(average_position) AS class_average_position,
        COUNT(*) AS car_count
    FROM car_stats
    GROUP BY car_class
)
SELECT
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cs.car_country
FROM car_stats cs
JOIN class_stats cls
    ON cls.car_class = cs.car_class
WHERE cls.car_count >= 2
  AND cs.average_position < cls.class_average_position
ORDER BY cs.car_class ASC, cs.average_position ASC;

-- Cначала считается статистика по каждой машине, потом средняя позиция по каждому классу и количество машин в нём. 
-- После этого оставляем только те классы, где минимум две машины, и выбираем автомобили, чья средняя позиция лучше средней позиции своего класса.

-- Задача 5
-- Определить, какие классы автомобилей имеют наибольшее количество автомобилей с низкой средней позицией (больше 3.0) 
-- и вывести информацию о каждом автомобиле из этих классов, включая его имя, класс, среднюю позицию, количество гонок, в которых он участвовал, страну производства 
-- класса автомобиля, а также общее количество гонок для каждого класса. Отсортировать результаты по количеству автомобилей с низкой средней позицией.
-- Решение: 

WITH car_stats AS (
    SELECT
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count,
        cl.country AS car_country
    FROM Cars c
    JOIN Results r
        ON r.car = c.name
    JOIN Classes cl
        ON cl.class = c.class
    GROUP BY c.name, c.class, cl.country
),
class_stats AS (
    SELECT
        car_class,
        SUM(race_count) AS total_races,
        SUM(CASE WHEN average_position >= 3.0 THEN 1 ELSE 0 END) AS low_position_count
    FROM car_stats
    GROUP BY car_class
)
SELECT
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cs.car_country,
    cls.total_races,
    cls.low_position_count
FROM car_stats cs
JOIN class_stats cls
    ON cls.car_class = cs.car_class
WHERE cs.average_position > 3.0
ORDER BY cls.low_position_count DESC, cs.car_name ASC;

-- Сначала считаем статистику по каждой машине, потом по каждому классу считаем общее число гонок и сколько машин имеют среднюю позицию не меньше 3.0.
-- После этого выводим только машины со средней позицией строго больше 3.0, поэтому получается ровно нужный результат.