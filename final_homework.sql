--Задание 1
SELECT 
    CONCAT(first_name, ' ', last_name, ' ', middle_name) AS fio,
    dob,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, dob)) AS Years
FROM 
    person
WHERE 
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, dob)) > 65;

--Задание 2  
SELECT COUNT(*)
FROM position pos
LEFT JOIN employee emp ON pos.pos_id = emp.pos_id 
WHERE emp.pos_id IS NULL;

--Задание 3
SELECT
    name,
    employees_id,
    assigned_id,
    COUNT(employee_id) AS emp_count
FROM
    projects,
    UNNEST(employees_id) as employee_id
GROUP BY
    name, employees_id, assigned_id;


--Задание 4
select
	*
from
	(
	select
		emp_id,
		effective_from,
		salary,
		coalesce(lag(salary) over (partition by emp_id
	order by
		effective_from),
		0)  prev_salary,
		coalesce(
        ((salary - lag(salary) over (partition by emp_id
	order by
		effective_from)) / lag(salary) over (partition by emp_id
	order by
		effective_from)) * 100,
		0
    )  change_percent
	from
		employee_salary
)
where
	change_percent = 25;


--Задание 5
SELECT
    EXTRACT(YEAR FROM created_at) AS year,
    ROUND(AVG(amount)::NUMERIC, 2) AS avg_amount
FROM
    projects
GROUP BY
    year
ORDER BY
    year;


--Задание 6
SELECT 
    full_name, 
    salary
FROM (
    SELECT
        CONCAT(p.first_name, ' ', p.last_name, ' ', p.middle_name) AS full_name,
        s.salary,
        MIN(s.salary) OVER() as min_salary,
        MAX(s.salary) OVER() as max_salary
    FROM 
        employee_salary s
    JOIN 
        employee e ON e.emp_id = s.emp_id
    JOIN 
        person p ON p.person_id = e.person_id
) subquery
WHERE salary = min_salary OR salary = max_salary;


--Задание 7
SELECT
    es.emp_id,
    es.salary,
    STRING_AGG(gs.grade::text, ', ') AS grades_as_string
FROM
    employee_salary es
JOIN
    grade_salary gs
ON
    es.salary BETWEEN gs.min_salary AND gs.max_salary
GROUP BY
    es.emp_id,
    es.salary;


--Задание 8
CREATE VIEW employee_i AS
SELECT 
    CONCAT(p.first_name, ' ', p.last_name, ' ', p.middle_name) AS full_name,
    pos.pos_title AS position,
    s.unit_title AS division,
    EXTRACT(YEAR FROM AGE(p.dob)) AS age,
    EXTRACT(YEAR FROM AGE(NOW(), e.hire_date)) * 12 + EXTRACT(MONTH FROM AGE(NOW(), e.hire_date)) AS months_in_company,
    es.salary AS current_salary,
    ARRAY(
        SELECT project_id FROM projects WHERE e.emp_id = ANY(employees_id)
    ) AS project_list
FROM
    employee e
    JOIN person p ON e.person_id = p.person_id
    JOIN position pos ON e.pos_id = pos.pos_id
    JOIN structure s ON pos.unit_id = s.unit_id
    LEFT JOIN (
        SELECT emp_id, salary 
        FROM(
            SELECT emp_id, salary, effective_from, ROW_NUMBER() OVER(PARTITION BY emp_id ORDER BY effective_from DESC) rn
            FROM employee_salary
        ) subquery 
        WHERE subquery.rn = 1
    ) es ON e.emp_id = es.emp_id;