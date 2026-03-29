-- База данных 4. Структура организации

-- Задача 1
-- Найти всех сотрудников, подчиняющихся Ивану Иванову (с EmployeeID = 1), включая их подчиненных и подчиненных подчиненных, а также самого Ивана Иванова.
-- Для каждого сотрудника вывести следующую информацию:
-- Решение:

WITH RECURSIVE subordinates AS (
    SELECT
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM Employees e
    WHERE e.EmployeeID = 1

    UNION ALL

    SELECT
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM Employees e
    JOIN subordinates s
        ON e.ManagerID = s.EmployeeID
)
SELECT
    s.EmployeeID,
    s.Name,
    s.ManagerID,
    d.DepartmentName,
    r.RoleName,
    STRING_AGG(DISTINCT p.ProjectName, ', ') AS project_names,
    STRING_AGG(DISTINCT t.TaskName, ', ') AS task_names
FROM subordinates s
LEFT JOIN Departments d
    ON d.DepartmentID = s.DepartmentID
LEFT JOIN Roles r
    ON r.RoleID = s.RoleID
LEFT JOIN Projects p
    ON p.DepartmentID = s.DepartmentID
LEFT JOIN Tasks t
    ON t.AssignedTo = s.EmployeeID
GROUP BY
    s.EmployeeID,
    s.Name,
    s.ManagerID,
    d.DepartmentName,
    r.RoleName
ORDER BY s.Name;

-- Cначала рекурсивно собираем Ивана Иванова и всех его подчинённых по цепочке через ManagerID.
-- Затем подтягиваем отдел, роль, проекты по отделу и задачи по сотруднику. STRING_AGG нужен, чтобы собрать несколько проектов и задач в одну строку,
-- а LEFT JOIN оставляет NULL, если у сотрудника их нет.

-- Задача 2
-- Найти всех сотрудников, подчиняющихся Ивану Иванову с EmployeeID = 1, включая их подчиненных и подчиненных подчиненных, а также самого Ивана Иванова.
-- Для каждого сотрудника вывести следующую информацию:
-- Решение:

WITH RECURSIVE subordinates AS (
    SELECT
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM Employees e
    WHERE e.EmployeeID = 1

    UNION ALL

    SELECT
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM Employees e
    JOIN subordinates s
        ON e.ManagerID = s.EmployeeID
)
SELECT
    s.EmployeeID,
    s.Name,
    s.ManagerID,
    d.DepartmentName,
    r.RoleName,
    STRING_AGG(DISTINCT p.ProjectName, ', ') AS project_names,
    STRING_AGG(DISTINCT t.TaskName, ', ') AS task_names,
    COUNT(DISTINCT t.TaskID) AS total_tasks,
    COUNT(DISTINCT e2.EmployeeID) AS total_subordinates
FROM subordinates s
LEFT JOIN Departments d
    ON d.DepartmentID = s.DepartmentID
LEFT JOIN Roles r
    ON r.RoleID = s.RoleID
LEFT JOIN Projects p
    ON p.DepartmentID = s.DepartmentID
LEFT JOIN Tasks t
    ON t.AssignedTo = s.EmployeeID
LEFT JOIN Employees e2
    ON e2.ManagerID = s.EmployeeID
GROUP BY
    s.EmployeeID,
    s.Name,
    s.ManagerID,
    d.DepartmentName,
    r.RoleName
ORDER BY s.Name;

-- Cначала рекурсивно собираются Иван Иванов и все его подчинённые по цепочке через ManagerID.
-- Потом для каждого сотрудника подтягиваются отдел, роль, проекты по его отделу, задачи, назначенные лично ему, а также считается число его прямых подчинённых.
-- LEFT JOIN оставляет NULL, если у сотрудника нет проектов или задач.

-- Задача 3
-- Найти всех сотрудников, которые занимают роль менеджера и имеют подчиненных (то есть число подчиненных больше 0).
-- Для каждого такого сотрудника вывести следующую информацию:

WITH RECURSIVE manager_hierarchy AS (
    SELECT
        e.EmployeeID AS manager_id,
        e.EmployeeID AS subordinate_id
    FROM Employees e
    JOIN Roles r
        ON r.RoleID = e.RoleID
    WHERE r.RoleName = 'Менеджер'

    UNION ALL

    SELECT
        mh.manager_id,
        e.EmployeeID AS subordinate_id
    FROM manager_hierarchy mh
    JOIN Employees e
        ON e.ManagerID = mh.subordinate_id
),
subordinate_counts AS (
    SELECT
        manager_id,
        COUNT(DISTINCT subordinate_id) - 1 AS TotalSubordinates
    FROM manager_hierarchy
    GROUP BY manager_id
    HAVING COUNT(DISTINCT subordinate_id) - 1 > 0
)
SELECT
    e.EmployeeID,
    e.Name AS EmployeeName,
    e.ManagerID,
    d.DepartmentName,
    r.RoleName,
    STRING_AGG(DISTINCT p.ProjectName, ', ') AS ProjectNames,
    STRING_AGG(DISTINCT t.TaskName, ', ') AS TaskNames,
    sc.TotalSubordinates
FROM Employees e
JOIN Roles r
    ON r.RoleID = e.RoleID
JOIN Departments d
    ON d.DepartmentID = e.DepartmentID
JOIN subordinate_counts sc
    ON sc.manager_id = e.EmployeeID
LEFT JOIN Projects p
    ON p.DepartmentID = e.DepartmentID
LEFT JOIN Tasks t
    ON t.AssignedTo = e.EmployeeID
WHERE r.RoleName = 'Менеджер'
GROUP BY
    e.EmployeeID,
    e.Name,
    e.ManagerID,
    d.DepartmentName,
    r.RoleName,
    sc.TotalSubordinates
ORDER BY e.Name;

-- Сначала рекурсивно для каждого сотрудника с ролью Менеджер строится вся цепочка его подчинённых, включая вложенные уровни.
-- Потом считается общее число таких подчинённых, исключая самого менеджера.
-- В финале подтягиваются отдел, роль, проекты по отделу и задачи сотрудника, а STRING_AGG собирает их в одну строку.