-- База данных 3. Бронирование отелей

-- Задача 1
-- Определить, какие клиенты сделали более двух бронирований в разных отелях, и вывести информацию о каждом таком клиенте, включая его имя, электронную почту,
-- телефон, общее количество бронирований, а также список отелей, в которых они бронировали номера (объединенные в одно поле через запятую). Также подсчитать среднюю длительность их пребывания (в днях) по всем бронированиям.
-- Отсортировать результаты по количеству бронирований в порядке убывания.
-- Решение:

SELECT
    c.name AS customer_name,
    c.email,
    c.phone,
    COUNT(b.id_booking) AS total_bookings,
    STRING_AGG(DISTINCT h.name, ', ' ORDER BY h.name) AS hotel_list,
    AVG(b.check_out_date - b.check_in_date) AS average_stay_days
FROM Customer c
JOIN Booking b
    ON b.ID_customer = c.ID_customer
JOIN Room r
    ON r.ID_room = b.ID_room
JOIN Hotel h
    ON h.ID_hotel = r.ID_hotel
GROUP BY c.ID_customer, c.name, c.email, c.phone
HAVING COUNT(b.ID_booking) > 2
   AND COUNT(DISTINCT h.ID_hotel) > 1
ORDER BY total_bookings DESC;

-- Cначала соединяем клиентов с бронированиями, номерами и отелями, потом группируем по клиенту. 
-- После этого оставляем только тех, у кого больше двух бронирований и они были сделаны более чем в одном отеле. 
-- STRING_AGG собирает список отелей в одну строку, а AVG(check_out_date - check_in_date) считает среднюю длительность проживания в днях.

-- Задача 2
-- Необходимо провести анализ клиентов, которые сделали более двух бронирований в разных отелях и потратили более 500 долларов на свои бронирования
-- Решение:

WITH frequent_customers AS (
    SELECT
        c.ID_customer,
        c.name,
        COUNT(b.ID_booking) AS total_bookings,
        COUNT(DISTINCT r.ID_hotel) AS unique_hotels,
        SUM(r.price) AS total_spent
    FROM Customer c
    JOIN Booking b
        ON b.ID_customer = c.ID_customer
    JOIN Room r
        ON r.ID_room = b.ID_room
    GROUP BY c.ID_customer, c.name
    HAVING COUNT(b.ID_booking) > 2
       AND COUNT(DISTINCT r.ID_hotel) > 1
),
high_spending_customers AS (
    SELECT
        c.ID_customer,
        c.name,
        SUM(r.price) AS total_spent,
        COUNT(b.ID_booking) AS total_bookings
    FROM Customer c
    JOIN Booking b
        ON b.ID_customer = c.ID_customer
    JOIN Room r
        ON r.ID_room = b.ID_room
    GROUP BY c.ID_customer, c.name
    HAVING SUM(r.price) > 500
)
SELECT
    fc.ID_customer,
    fc.name,
    fc.total_bookings,
    fc.total_spent,
    fc.unique_hotels
FROM frequent_customers fc
JOIN high_spending_customers hsc
    ON hsc.ID_customer = fc.ID_customer
ORDER BY fc.total_spent ASC;

-- Cначала выбираются клиенты с более чем двумя бронированиями в разных отелях, потом отдельно — клиенты с суммой бронирований больше 500.
-- В конце эти выборки соединяются, чтобы оставить только тех, кто подходит под оба условия. total_spent считается как сумма price по всем забронированным номерам.

-- Задача 3
-- Вам необходимо провести анализ данных о бронированиях в отелях и определить предпочтения клиентов по типу отелей

WITH hotel_category AS (
    SELECT
        h.ID_hotel,
        h.name AS hotel_name,
        AVG(r.price) AS avg_price,
        CASE
            WHEN AVG(r.price) < 175 THEN 'Cheap'
            WHEN AVG(r.price) <= 300 THEN 'Medium'
            ELSE 'Expensive'
        END AS category
    FROM Hotel h
    JOIN Room r
        ON r.ID_hotel = h.ID_hotel
    GROUP BY h.ID_hotel, h.name
),
customer_hotels AS (
    SELECT
        c.ID_customer,
        c.name,
        hc.category,
        hc.hotel_name
    FROM Customer c
    JOIN Booking b
        ON b.ID_customer = c.ID_customer
    JOIN Room r
        ON r.ID_room = b.ID_room
    JOIN hotel_category hc
        ON hc.ID_hotel = r.ID_hotel
),
customer_pref AS (
    SELECT
        ID_customer,
        name,
        MAX(CASE WHEN category = 'Expensive' THEN 1 ELSE 0 END) AS has_expensive,
        MAX(CASE WHEN category = 'Medium' THEN 1 ELSE 0 END) AS has_medium,
        MAX(CASE WHEN category = 'Cheap' THEN 1 ELSE 0 END) AS has_cheap
    FROM customer_hotels
    GROUP BY ID_customer, name
)
SELECT
    cp.ID_customer,
    cp.name,
    CASE
        WHEN cp.has_expensive = 1 THEN 'Expensive'
        WHEN cp.has_medium = 1 THEN 'Medium'
        ELSE 'Cheap'
    END AS preferred_hotel_type,
    STRING_AGG(DISTINCT ch.hotel_name, ', ' ORDER BY ch.hotel_name) AS visited_hotels
FROM customer_pref cp
JOIN customer_hotels ch
    ON ch.ID_customer = cp.ID_customer
GROUP BY cp.ID_customer, cp.name, cp.has_expensive, cp.has_medium
ORDER BY
    CASE
        WHEN cp.has_expensive = 0 AND cp.has_medium = 0 THEN 1
        WHEN cp.has_expensive = 0 AND cp.has_medium = 1 THEN 2
        ELSE 3
    END,
    cp.name;

-- Сначала считаем среднюю цену по каждому отелю и присваиваем категорию. Затем смотрим, какие категории отелей посещал каждый клиент. 
-- Через MAX(CASE) определяем, есть ли у клиента дорогие/средние/дешевые отели, и на основе этого задаём приоритет.
-- В конце собираем список посещённых отелей и сортируем по требуемому порядку категорий.