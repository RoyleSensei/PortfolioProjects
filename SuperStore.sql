BEGIN

/*
--1.country
*/

insert into ss_country(country_id, country_name)
select seq_ss_country.nextval,
        country
from(
    select distinct country
    from ss_stage
    where country is not null
    minus
    --so we don't load duplicates
    select country_name
    from ss_country
);


/*
--2. Region
*/

insert into ss_region(region_id, region_name, country_id)
select seq_ss_region.nextval region_id, -- sequence 
       region region_name, -- stage
       country_id --stage via lookup
from (
    select distinct ss_stage.region, ss_country.country_id
    from ss_stage,
        ss_country
        where ss_stage.country = ss_country.country_name
        minus 
        select region_name, country_id
        from ss_region   
);


/*
----3.STATE
*/

insert into ss_state(state_id, state_name, region_id)
select seq_ss_state.nextval state_id, -- sequence 
       state_or_province state_name, -- stage
       region_id --stage via lookup
from (
    select distinct ss_stage.state_or_province, ss_region.region_id
    from ss_stage,
        ss_region
        where ss_stage.region = ss_region.region_name
        minus 
        select state_name, region_id
        from ss_state   
);


/*
----4.Location
*/

insert into ss_location(location_id, city_name, postal_code, state_id)
select seq_ss_location.nextval location_id, -- sequence 
       city city_name, -- stage
       postal_code, -- stage
       state_id --stage via lookup
from (
    select distinct ss_stage.city, ss_stage.postal_code, ss_state.state_id
    from ss_stage,
        ss_state
        where ss_stage.state_or_province = ss_state.state_name
        minus 
        select city_name, postal_code, state_id
        from ss_location  
);


/*
----5.Customer_segment
*/

insert into ss_customer_segment(segment_id, segment_name)
select seq_ss_segment.nextval segment_id,
        customer_segment
from(
    select distinct customer_segment
    from ss_stage
    where customer_segment is not null
    minus
    --so we don't load duplicates
    select segment_name
    from ss_customer_segment
);


/*
----6.Customer
*/

insert into ss_customer(customer_pk, customer_name, customer_id_in)
select seq_ss_customer.nextval customer_pk, --sequence
        customer_name, --stage
        customer_id customer_id_in  
from(
    select distinct customer_name, customer_id
    from ss_stage
    where customer_name is not null
    minus
    --so we don't load duplicates
    select customer_name, customer_id_in 
    from ss_customer
);


/*
--7.Priority
*/

insert into ss_priority(orderp_id, priority)
select seq_ss_priority.nextval orderp_id,
        order_priority priority
from(
    select distinct order_priority
    from ss_stage 
    where order_priority is not null
    minus
    select priority
    from ss_priority
);


/*
--8.Order
*/

insert into ss_order(order_id, order_date, orderp_id, 
                customer_pk, segment_id, location_id)
select seq_ss_order.nextval order_id,
        order_date,
        orderp_id,
        customer_pk,
        segment_id, 
        location_id
from (
    select distinct order_date, ss_priority.orderp_id, ss_customer.customer_pk,
                ss_customer_segment.segment_id, ss_location.location_id
    from ss_stage,
        ss_customer,
        ss_priority,
        ss_customer_segment,
        ss_location
    where ss_stage.customer_name = ss_customer.customer_name
        and ss_stage.order_priority = ss_priority.priority
        and ss_stage.customer_segment = ss_customer_segment.segment_name
        and ss_stage.city = ss_location.city_name
    minus 
    select order_date, orderp_id, customer_pk, segment_id, location_id
    from ss_order
);
    
    
/*
--9.ship_mode
*/


insert into ss_ship_mode(mode_id, mode_name)
select seq_ss_mode.nextval mode_id, 
       ship_mode mode_name
from (
    select distinct ship_mode
    from ss_stage
    where ship_mode is not null
    minus 
    --so we don't load duplicates
    select mode_name
    from ss_ship_mode
);


/*
--10.ss_container
*/


insert into ss_container(container_id, container_name)
select seq_ss_container.nextval container_id,
        product_container container_name
from (
    select distinct product_container
    from ss_stage
    where product_container is not null
    minus
    select container_name
    from ss_container
);



/*
--11.category
*/

---first insert

insert into ss_category(category_id, category_name)
select seq_ss_category.nextval category_id, 
    product_category category_name
from (
    select distinct product_category
    from ss_stage
    where product_category is not null
    minus
    select category_name
    from ss_category);

-- second insert

insert into ss_category(category_id, category_name, parent_category_id)
select seq_ss_category.nextval category_id, 
    product_sub_category category_name,
    category_id parent_category_id
from(
    select distinct product_sub_category, category_id
    from ss_stage, ss_category
    where ss_stage.product_category = ss_category.category_name
    );

/*
--12. ss_product
*/


insert into ss_product(product_id, product_name, unit_price, shipping_cost,
    category_id, container_id) 
select seq_ss_prdt.nextval product_id,
    product_name,
    unit_price,
    shipping_cost,
    category_id, container_id
from (
    select distinct product_name,
        unit_price, shipping_cost, category_id, container_id
    from ss_stage,
        ss_category,
        ss_container
    where ss_stage.product_sub_category = ss_category.category_name
    and ss_stage.product_container = ss_container.container_name
    minus
    select product_name,
        unit_price, shipping_cost, category_id, container_id
    from ss_product
);

/*
--13.order_item
*/

insert into ss_order_item(order_item_id, quantity, discount, 
    profit, sales, ship_date,order_id, product_id, mode_id)
select seq_ss_item.nextval order_item_id, 
        quantity_ordered_new quantity,
        discount, 
        profit, 
        sales, 
        ship_date, order_id,
        product_id, mode_id
from (
    select distinct quantity_ordered_new, discount, profit, 
                sales, ship_date, ss_order.order_id, product_id, mode_id
    from ss_stage, ss_order, ss_product, ss_ship_mode
    where ss_stage.order_id = ss_order.order_id
        and ss_stage.product_name = ss_product.product_name
        and ss_stage.ship_mode = ss_ship_mode.mode_name
    minus
    select quantity, discount, profit, sales, 
        ship_date,order_id, product_id, mode_id
    from ss_order_item
);


/*
--14.base_margin
*/

insert into ss_base_margin(margin_id, base_margin, segment_id, product_id)
select seq_ss_base.nextval margin_id, 
    base_margin, 
    segment_id, 
    product_id
from (
    select distinct product_base_margin base_margin,
        segment_id,
        product_id
    from ss_stage, ss_customer_segment, ss_product
    where ss_stage.customer_segment=ss_customer_segment.segment_name
    and ss_stage.product_name=ss_product.product_name
    minus
    select base_margin, segment_id, product_id
    from ss_base_margin  
);


COMMIT;

END;
/
