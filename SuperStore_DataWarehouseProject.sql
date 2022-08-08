
BEGIN 

--1. DW_SEGMENT

insert into ss_dw_segment(segment_pk, customer_segment_tx)
select segment_id segment_pk, 
        segment_name customer_segment_tx
from(
    select distinct segment_id, segment_name
    from ss_customer_segment
    where segment_name IS NOT NULL
    minus
    select segment_pk, customer_segment_tx
    from ss_dw_segment
);

--2. DW_CUSTOMER

insert into ss_dw_customer(customer_pk, customer_id_nr, customer_name_tx)
select  customer_pk,
        customer_id_in customer_id_nr,
        customer_name customer_name_tx
from(
    select distinct customer_pk, customer_id_in, customer_name
    from ss_customer
    where customer_pk is not null 
    and customer_id_in is not null
    and customer_name is not null
    minus 
    select customer_pk, customer_id_nr, customer_name_tx
    from ss_dw_customer
);

--3. DW_PERIOD

insert into ss_dw_period(period_pk, period_dt, month_nr, 
                            month_tx, quarter_tx, year_nr)
select seq_dw_period.nextval period_pk,
    order_date period_dt,
    to_number(to_char(order_date, 'mm')) month_nr,
    to_char(order_date, 'MONTH') month_tx,
    to_char(order_date, 'yyyy "Q"Q') quarter_tx,
    extract (year from order_date) year_nr
from (
    select distinct order_date
    from ss_order
    where order_date is not null
    minus 
    select period_dt
    from ss_dw_period
);

--4. DW_LOCATION

insert into ss_dw_location(location_pk, country_tx, region_tx, 
                            state_tx, city_tx, zip_tx, location_in_id_nr)
select seq_dw_loc.nextval location_pk,
        country_name country_tx,
        region_name region_tx,
        state_name state_tx,
        city_name city_tx,
        postal_code zip_tx,
        location_id location_in_id_nr
from (
    select distinct ss_country.country_name,
                    ss_region.region_name,
                    ss_state.state_name,
                    ss_location.city_name,
                    ss_location.postal_code,
                    ss_location.location_id
    from ss_country, ss_region, ss_state, ss_location
    where ss_country.country_id = ss_region.country_id
    and ss_region.region_id = ss_state.region_id
    and ss_state.state_id = ss_location.state_id
    minus
    select country_tx, region_tx, state_tx, city_tx, zip_tx, location_in_id_nr
    from ss_dw_location
);

--5. DW_PRODUCT

insert into ss_dw_product(product_pk, product_name_tx, container_tx, 
                            category_tx, sub_category_tx)
select seq_dw_pdct.nextval product_pk,
    product_name product_name_tx,
    container_name container_tx,
    parent category_tx,
    sub_category sub_category_tx
from(
    select distinct ss_product.product_name, 
        ss_container.container_name,
        parent.category_name parent,
        sub.category_name sub_category
    from ss_product,
        ss_container,
        ss_category parent, 
        ss_category sub
    where ss_product.container_id = ss_container.container_id
    and parent.category_id = sub.parent_category_id
    minus
    select product_name_tx, container_tx, 
            category_tx, sub_category_tx
    from ss_dw_product
);

--6. DW_DATA

insert into ss_dw_data(data_pk, order_id_nr, quantity_nr, unit_price_nr, base_margin_nr,
    sales_nr, profit_nr, discount_nr, ship_date_dt, ship_cost_nr,
    ship_mode_tx, priority_tx, period_fk, location_fk, segment_fk, 
    product_fk, customer_fk)
select seq_dw_data.nextval data_pk,
                order_id_nr,
                quantity_nr,
                unit_price_nr,
                base_margin_nr,
                sales_nr,
                profit_nr,
                discount_nr,
                ship_date_dt,
                ship_cost_nr,
                ship_mode_tx,
                priority_tx,
                period_fk,
                location_fk,
                segment_fk,
                product_fk,
                customer_fk
from (
    select distinct ss_order.order_id order_id_nr,
                    ss_order_item.quantity quantity_nr,
                    ss_product.unit_price unit_price_nr,
                    ss_base_margin.base_margin base_margin_nr,
                    ss_order_item.sales sales_nr,
                    ss_order_item.profit profit_nr,
                    ss_order_item.discount discount_nr,
                    ss_order_item.ship_date ship_date_dt,
                    ss_product.shipping_cost ship_cost_nr,
                    ss_ship_mode.mode_name ship_mode_tx,
                    ss_priority.priority priority_tx,
                    ss_dw_period.period_pk period_fk,
                    ss_dw_location.location_pk location_fk,
                    ss_dw_segment.segment_pk segment_fk,
                    ss_dw_product.product_pk product_fk,
                    ss_dw_customer.customer_pk customer_fk
    from ss_order,
        ss_product,
        ss_order_item,
        ss_base_margin,
        ss_ship_mode,
        ss_priority,
        ss_dw_period,
        ss_dw_location,
        ss_dw_segment,
        ss_dw_product,
        ss_dw_customer
    where ss_order.orderp_id = ss_priority.orderp_id
    and ss_order.order_date = ss_dw_period.period_dt
    and ss_order.order_id = ss_order_item.order_id
    and ss_order_item.mode_id = ss_ship_mode.mode_id
    and ss_order_item.product_id = ss_product.product_id
    and ss_product.product_id = ss_base_margin.product_id
    and ss_product.product_name = ss_dw_product.product_name_tx
    and ss_base_margin.segment_id = ss_dw_segment.segment_pk
    and ss_order.customer_fk = ss_dw_customer.customer_pk
    and ss_order.location_id = ss_dw_location.location_in_id_nr
    minus
    select  order_id_nr, 
            quantity_nr, 
            unit_price_nr, 
            base_margin_nr,
            sales_nr, 
            profit_nr, 
            discount_nr, 
            ship_date_dt, 
            ship_cost_nr,
            ship_mode_tx, 
            priority_tx, 
            period_fk, 
            location_fk, 
            segment_fk, 
            product_fk, 
            customer_fk
    from ss_dw_data
);

commit;

end;
/
