BEGIN

# user_orders contains number of orders and total amount per user per city
create table if not exists `efood2022-377414.main_assessment.user_orders`
as
  ( select user_id, sum(orders) as total_orders,city, array_agg(struct(cuisine, amount, orders as cuisine_orders)) as values
    from (
      select user_id, cuisine, city, sum(amount) as amount, count(order_id) as orders
      from  `efood2022-377414.main_assessment.orders`
      group by user_id, cuisine, city
      order by city
    )
    group by user_id, city
  );

# city_per_cuisine_users contains number of users and orders for 'breakfast' for the top 5 cities
create table if not exists `efood2022-377414.main_assessment.city_per_cuisine_users`
as
  ( 
    select foo.city, foo.users, bar.breakfast_orders
    from (
      select city, count(distinct user_id) as users, 
      from `efood2022-377414.main_assessment.user_orders` 
      group by city
      order by city
    ) as foo,
    (
      select city, count(distinct user_id) as breakfast_orders 
      from `efood2022-377414.main_assessment.user_orders` , unnest(values) as values 
      where cuisine = 'Breakfast'
      group by city
      order by breakfast_orders*(-1) asc
      limit 5
    ) as bar
    where foo.city = bar.city
  );

# using calculated tables to calculate basket, frequency and frequency for users with more than 3 orders
select foo.city,
       breakfast_basket,
       efood_basket,
       breakfast_freq,
       efood_freq,
       breakfast_users3freq_perc,
       efood_users3freq_perc
from (
  select city,
        sum(values.amount)/sum(values.cuisine_orders) as efood_basket,
        sum(values.cuisine_orders)/count(distinct user_id) as efood_freq
  from `efood2022-377414.main_assessment.user_orders`, unnest(values) as values
  group by city
  having sum(cuisine_orders) > 1000
) as foo,
(
  select user_orders.city,
        count(user_id)/ city_per_cuisine_users.users as efood_users3freq_perc
  from `efood2022-377414.main_assessment.user_orders` as user_orders,
      `efood2022-377414.main_assessment.city_per_cuisine_users`as city_per_cuisine_users
  where total_orders > 3 and user_orders.city = city_per_cuisine_users.city
  group by user_orders.city, city_per_cuisine_users.users
) as bar,
(
  select city,
        sum(values.amount)/sum(values.cuisine_orders) as breakfast_basket,
        sum(values.cuisine_orders)/count(distinct user_id) as breakfast_freq
  from `efood2022-377414.main_assessment.user_orders`, unnest(values) as values
  where values.cuisine = 'Breakfast'
  group by city
  having sum(cuisine_orders) > 1000
) as breakfast_foo,
(
  select user_orders.city,
        count(user_id)/ city_per_cuisine_users.breakfast_orders as breakfast_users3freq_perc
  from `efood2022-377414.main_assessment.user_orders` as user_orders, 
       unnest(values) as values,
      `efood2022-377414.main_assessment.city_per_cuisine_users`as city_per_cuisine_users
  where values.cuisine_orders > 3 and values.cuisine = 'Breakfast' and user_orders.city = city_per_cuisine_users.city
  group by user_orders.city, city_per_cuisine_users.users, city_per_cuisine_users.breakfast_orders
) as breakfast_bar
where foo.city = bar.city and bar.city = breakfast_foo.city and breakfast_foo.city = breakfast_bar.city;


drop table if exists `efood2022-377414.main_assessment.user_orders`;
drop table if exists `efood2022-377414.main_assessment.city_per_cuisine_users`;

END