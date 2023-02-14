BEGIN

# user_orders_per_city contains the number of orders for top 10 users per city
create table if not exists `efood2022-377414.main_assessment.user_orders_per_city`
as (
select city, sum(orders_per_user_per_city) as orders_per_city, array_agg(struct(user_id, orders_per_user_per_city)limit 10) as values
    from (
      select city, user_id, count(order_id) as orders_per_user_per_city
      from  `efood2022-377414.main_assessment.orders`
      group by user_id, city
      order by city, orders_per_user_per_city*(-1)
    )
group by city
order by city asc
);

# using calculated table to find the percentage of top 10 users' orders in each city
select city, concat(round((orders_of_top_10_users/orders_per_city)*100,0), '%') as orders_percentage_of_top_10_users 
from (
  select city, sum(values.orders_per_user_per_city) as orders_of_top_10_users, orders_per_city
  from `efood2022-377414.main_assessment.user_orders_per_city`, unnest(values) as values
  group by city, orders_per_city
  order by city
  )
group by city, orders_of_top_10_users, orders_per_city
order by city asc;

drop table `efood2022-377414.main_assessment.user_orders_per_city`;

END