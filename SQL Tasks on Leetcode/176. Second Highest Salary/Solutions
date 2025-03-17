**1. Use LIMIT 1 OFFSET 1 with COALESCE**
```sql
select COALESCE(
    (select distinct salary
    from Employee
    order by salary desc
    limit 1 offset 1), 
null) as SecondHighestSalary 
```
**2. Use max() and case when**
```sql
SELECT CASE 
        WHEN COUNT(DISTINCT salary) > 1 
        THEN (SELECT MAX(salary) 
              FROM Employee 
              WHERE salary < (SELECT MAX(salary) FROM Employee))
        ELSE NULL 
       END AS SecondHighestSalary
FROM Employee;
```
