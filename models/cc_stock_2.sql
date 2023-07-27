with cc_sales_products as (select * from {{ ref("cc_sales_products") }}),
    stg_cc_stock as (
        select
            # ## Key ###
            concat(model, "_", color, "_", ifnull(size, "no-size")) as product_id,
            # ##########
            model,
            color,
            size,
            -- name
            model_name,
            color_name,
            concat(
                model_name,
                " ",
                color_name,
                if(size is null, "", concat(" - Taille ", size))
            ) as product_name,
            -- product info --
            t.new as pdt_new,
            -- stock metrics --
            forecast_stock,
            stock,
            -- value
            price
        from `dbt_intro_1.raw_cc_stock` t
    )

select
    # ## Key ###
    product_id,
    # ##########
    model,
    color,
    size,
    -- category
    case
        when regexp_contains(lower(model_name), 't-shirt')
        then 'T-shirt'
        when regexp_contains(lower(model_name), 'short')
        then 'Short'
        when regexp_contains(lower(model_name), 'legging')
        then 'Legging'
        when regexp_contains(lower(replace(model_name, "è", "e")), 'brassiere|crop-top')
        then 'Crop-top'
        when regexp_contains(lower(model_name), 'débardeur|haut')
        then 'Top'
        when regexp_contains(lower(model_name), 'tour de cou|tapis|gourde')
        then 'Accessories'
        else null
    end as model_type,
    -- name
    model_name,
    color_name,
    product_name,
    -- product info --
    pdt_new,
    -- stock metrics --
    forecast_stock,
    stock,
    if(stock > 0, 1, 0) as in_stock,
    -- value
    price,
    if(stock < 0, null, round(stock * price, 2)) as stock_value,
    -- nb days --
    d.avg_daily_qty_91,
    safe_divide(t.stock, d.avg_daily_qty_91) as nb_day_stock
from stg_cc_stock t
left join `cc_sales_products` d using (product_id)
where true
order by product_id
