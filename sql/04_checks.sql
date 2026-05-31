CREATE OR REPLACE VIEW analytics.v_model_checks AS
SELECT 'raw rows' AS check_name, count(*)::TEXT AS check_value
FROM staging.mock_data
UNION ALL
SELECT 'fact rows', count(*)::TEXT
FROM analytics.fact_sales
UNION ALL
SELECT 'customers', count(*)::TEXT
FROM analytics.dim_customer
UNION ALL
SELECT 'sellers', count(*)::TEXT
FROM analytics.dim_seller
UNION ALL
SELECT 'products', count(*)::TEXT
FROM analytics.dim_product
UNION ALL
SELECT 'stores', count(*)::TEXT
FROM analytics.dim_store
UNION ALL
SELECT 'suppliers', count(*)::TEXT
FROM analytics.dim_supplier
UNION ALL
SELECT 'countries', count(*)::TEXT
FROM analytics.dim_country
UNION ALL
SELECT 'fact total amount', sum(sale_total_price)::TEXT
FROM analytics.fact_sales;

CREATE OR REPLACE VIEW analytics.v_sales_by_product_category AS
SELECT
    category.product_category_name,
    count(*) AS sales_count,
    sum(fact.sale_quantity) AS sold_items,
    sum(fact.sale_total_price) AS total_amount
FROM analytics.fact_sales fact
JOIN analytics.dim_product product
    ON product.product_key = fact.product_key
JOIN analytics.dim_product_category category
    ON category.product_category_key = product.product_category_key
GROUP BY category.product_category_name;
