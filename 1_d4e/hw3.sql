-- 1. Case When, NVL()
-- With table SalesPerson
-- Select top 10 * from Sales.SalesPerson;
-- 1. Select BusinessEntity , TerritoryID , SaleQuota , Bonus, CommissionPct , SalesYTD , SalesLastYear with Sales don’t have territory.
Select 
    BusinessEntityID, TerritoryID, SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear
from Sales.SalesPerson
where TerritoryID is null;
-- 2. Select BusinessEntity , TerritoryID , SaleQuota , Bonus, CommissionPct , SalesYTD , SalesLastYear with Sales missing KPI.
Select 
    BusinessEntityID, TerritoryID, SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear
from Sales.SalesPerson
where SalesQuota is null;
-- 3. With sales in question 1, 2. Give them TerritoryID = 11 and SaleQuota = 500.000
Select 
    BusinessEntityID, 
    isnull(TerritoryID, 11) TerritoryID, 
    isnull(SalesQuota, 500000) SalesQuota, 
    Bonus, CommissionPct, SalesYTD, SalesLastYear
from Sales.SalesPerson;
-- 4. Select list of persons, who not pass KPI.
Select * from Sales.SalesPerson
where SalesYTD < SalesQuota;
-- 5. Add column rank to the table with conditions follow:
-- SalesYTD >= 4m: excellent
-- 4m > SalesYTD >= 3m: very good
-- 3m > SalesYTD >= 1.5m: good
-- 1.5m > SalesYTD : strong pass
select 
    BusinessEntityID, 
    isnull(TerritoryID, 11) TerritoryID, 
    isnull(SalesQuota, 500000) SalesQuota, 
    Bonus, CommissionPct, SalesYTD, SalesLastYear,
    case when SalesYTD < 1500000 then 'strong pass'
        when SalesYTD >= 1500000 and SalesYTD < 3000000 then 'good'
        when SalesYTD >= 3000000 and SalesYTD < 4000000 then 'very good'
    else 'excellent' end rank
from Sales.SalesPerson;
-- 6. Add column status to the table with conditions follow:
-- SalesYTD > 1.5 * SalesLastYear : Tiger
-- 1.5 * SalesLastYear >= SalesYTD > SalesLastYear : Puma
-- SalesLastYear >= SalesYTD : Cat 
select 
    BusinessEntityID, 
    isnull(TerritoryID, 11) TerritoryID, 
    isnull(SalesQuota, 500000) SalesQuota, 
    Bonus, CommissionPct, SalesYTD, SalesLastYear,
    case when SalesYTD < 1500000 then 'strong pass'
        when SalesYTD >= 1500000 and SalesYTD < 3000000 then 'good'
        when SalesYTD >= 3000000 and SalesYTD < 4000000 then 'very good'
        else 'excellent' end rank,
    case when SalesYTD <= SalesLastYear then 'Cat'
        when SalesYTD > SalesLastYear and SalesYTD <= 1.5 * SalesLastYear then 'Puma'
        else 'Tiger' end 'status'
from Sales.SalesPerson;

-- 2. GROUP BY, HAVING
-- Select top 10 * from Sales.SalesPerson;
-- With table SalesPerson
-- 1. Find the average SalesQuote , total SaleYTD by TerritoryID
Select 
    TerritoryID,
    avg(SalesQuota) avg_sales_quota,
    sum(SalesYTD) total_sales_ytd
FROM Sales.SalesPerson
group by TerritoryID;
-- 2. Find total commissionPct , spread of revenue between this year and last year.
SELECT
    territoryID,
    sum(CommissionPct) total_commissionPct,
    sum(SalesYTD) - sum(SalesLastYear) spread
from Sales.SalesPerson
group by TerritoryID;
-- 3. Select TerritoryID , average SalesQuote , total SaleYTD , , total SaleLastYear , % increase of revenue then Sort TerritoryID by % increase of revenue.
select 
    TerritoryID,
    avg(SalesQuota) avg_sales_quota,
    sum(SalesYTD) total_sales_ytd,
    sum(SalesLastYear) total_sales_last_year,
    concat((sum(SalesLastYear) - sum(SalesYTD)) / sum(SalesYTD) * 100, '%') pct_increased_revenue
from Sales.SalesPerson
group by TerritoryID
order by pct_increased_revenue;

-- With table SalesOrderDetail
select top 10 * from Sales.SalesOrderDetail;
-- 1. Select saleOrderID , total productid by saleOrderID
select 
    SalesOrderID,
    count(ProductID) num_product_id
from Sales.SalesOrderDetail
group by SalesOrderID;
-- 2. Select productID , total OrderQty , total LineTotal , total revenue by product with total OrderQty >1000
select 
    ProductID,
    sum(OrderQty) total_orders,
    sum(LineTotal) total_line_total

from Sales.SalesOrderDetail
group by ProductID
having sum(OrderQty) > 1000;
-- 3. Select saleOrderID and total discount amount of this order.
select
    SalesOrderID,
    sum(UnitPriceDiscount * LineTotal) total_discount
 from Sales.SalesOrderDetail
 group by SalesOrderID;

 -- 3. JOIN
--  With table: SalesOrderHeader , Employee
-- select top 10 * from Sales.SalesOrderHeader;
-- select top 10 * from HumanResources.Employee;
-- select top 10 * from Person.Person;
-- (Default columns: Id, Firstname , lastname)
-- 1. Select order and employees name.
Select SalesOrderID,
    BusinessEntityID,
    concat(FirstName, ' ', LastName) fullname
from Sales.SalesOrderHeader soh
inner join Person.Person p 
on SalesPersonID = BusinessEntityID;
-- 2. Find 3 best sellers by order quantity.
select BusinessEntityID,
    FirstName, 
    LastName
from Person.Person
where BusinessEntityID in (
    -- get ids by sorting data by order quantity
    select top 3 SalesPersonID
    from Sales.SalesOrderHeader
    where SalesPersonID is not null
    group by SalesPersonID
    order by count(*) desc
);
-- 3. Find 3 best sellers by revenue.
select
    BusinessEntityID,
    FirstName,
    LastName
from Person.Person
where BusinessEntityID in (
    select top 3 SalesPersonID
    from Sales.SalesOrderHeader
    where SalesPersonID is not null
    group by SalesPersonID
    order by sum(subtotal) desc
);

-- With table: IndividualCustomer , SalesOrderHeader , Employee
-- (Default columns: Id, Firstname , lastname)
-- select top 10 * from Sales.SalesOrderHeader;
-- select top 10 * from HumanResources.Employee;
-- select top 10 * from Person.Person;
-- 1. Select order, customers name and sellers name
with CustomerT as (
    select SalesOrderID, concat(FirstName, ' ', LastName) customer_name
    from Sales.SalesOrderHeader
    left join Person.Person 
    on CustomerID = BusinessEntityID
),
-- select * from CustomerT
-- order by SalesOrderID;
SalesPersonT as (
    select SalesOrderID, concat(FirstName, ' ', LastName) salesperson_name
    from Sales.SalesOrderHeader
    left join Person.Person 
    on SalesPersonID = BusinessEntityID
)
-- select * from SalesPersonT
-- order by SalesOrderID;
select ct.SalesOrderID,
    customer_name,
    salesperson_name
from CustomerT ct 
inner join SalesPersonT st 
on ct.SalesOrderID = st.SalesOrderID
order by ct.SalesOrderID;
-- 2. Find top 5 customer by revenue
select top 5 CustomerID,
    sum(subtotal) revenue
from Sales.SalesOrderHeader 
group by CustomerID
order by revenue desc;
-- 3. Find top 5 customer by profit
-- select top 10 * from Production.product;
-- select top 10 * from Sales.SalesOrderDetail;
-- select top 10 * from Sales.SalesOrderHeader;
-- select 
--     SalesOrderID, 
--     sum(p.standardcost * OrderQty) total_cost
-- from Sales.SalesOrderDetail sod
-- inner join Production.Product p
-- on sod.productID = p.productID
-- group by SalesOrderID;

with CostT as (
    select 
    SalesOrderID, 
    sum(p.standardcost * OrderQty) total_cost
    from Sales.SalesOrderDetail sod
    inner join Production.Product p
    on sod.productID = p.productID
    group by SalesOrderID   
)

select top 5 CustomerID,
    sum(subtotal) - sum(total_cost) profit
from Sales.SalesOrderHeader
inner join CostT 
on Sales.SalesOrderHeader.SalesOrderID = CostT.SalesOrderID
group by CustomerID
order by profit desc;
--HW
select top 10 * from HumanResources.EmployeeDepartmentHistory;
select top 10 * from HumanResources.Department;
-- 1. Find employees and their last department. (EmployeeDepartmentHistory)
select 
    BusinessEntityID, edh.DepartmentID dept_id, d.name dept_name
from HumanResources.EmployeeDepartmentHistory edh
inner join HumanResources.Department d
on edh.DepartmentID = d.DepartmentID;
-- 2. Find 3 best sellers by commission.
-- select top 10 * from Sales.SalesPerson;
select top 3 BusinessEntityID,
    CommissionPct * SalesYTD commission 
from Sales.SalesPerson
order by commission desc;
-- 3. With table [ SalesOrderDetail ] Add column ‘StandardCost’ from table [Production].[Product] and ‘CustomerID’ from table [SalesOrderHeader]
select * from Sales.SalesOrderDetail;
select * from Production.Product;
select * from Sales.SalesOrderHeader;
SELECT
    sod.SalesOrderDetailID,
    sod.productID,
    sod.SalesOrderID,
    prd.StandardCost,
    soh.CustomerID
from 
    Sales.SalesOrderDetail sod, 
    Sales.SalesOrderHeader soh,
    Production.Product prd
where 
    sod.SalesOrderID = soh.SalesOrderID
    and sod.productID = prd.productID; 
-- 4. Select detail order have status = 5
select * from Sales.SalesOrderDetail
where SalesOrderID in (
    select SalesOrderID from Sales.SalesOrderHeader where status = 5
);
-- 5. Research about SubQuery in SQL and the difference between table and view