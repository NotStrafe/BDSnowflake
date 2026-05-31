TRUNCATE TABLE
    analytics.fact_sales,
    analytics.dim_date,
    analytics.dim_customer_pet,
    analytics.dim_customer,
    analytics.dim_seller,
    analytics.dim_product,
    analytics.dim_supplier,
    analytics.dim_store,
    analytics.dim_pet_type,
    analytics.dim_pet_breed,
    analytics.dim_product_category,
    analytics.dim_pet_category,
    analytics.dim_brand,
    analytics.dim_material,
    analytics.dim_country
RESTART IDENTITY CASCADE;

INSERT INTO analytics.dim_country (country_name)
SELECT DISTINCT country_name
FROM (
    SELECT customer_country AS country_name FROM staging.mock_data
    UNION
    SELECT seller_country FROM staging.mock_data
    UNION
    SELECT store_country FROM staging.mock_data
    UNION
    SELECT supplier_country FROM staging.mock_data
) countries
WHERE country_name IS NOT NULL
ORDER BY country_name;

INSERT INTO analytics.dim_pet_type (pet_type_name)
SELECT DISTINCT customer_pet_type
FROM staging.mock_data
ORDER BY customer_pet_type;

INSERT INTO analytics.dim_pet_breed (pet_breed_name)
SELECT DISTINCT customer_pet_breed
FROM staging.mock_data
ORDER BY customer_pet_breed;

INSERT INTO analytics.dim_product_category (product_category_name)
SELECT DISTINCT product_category
FROM staging.mock_data
ORDER BY product_category;

INSERT INTO analytics.dim_pet_category (pet_category_name)
SELECT DISTINCT pet_category
FROM staging.mock_data
ORDER BY pet_category;

INSERT INTO analytics.dim_brand (product_brand_name)
SELECT DISTINCT product_brand
FROM staging.mock_data
ORDER BY product_brand;

INSERT INTO analytics.dim_material (product_material_name)
SELECT DISTINCT product_material
FROM staging.mock_data
ORDER BY product_material;

INSERT INTO analytics.dim_customer (
    source_customer_id, first_name, last_name, age, email, country_key, postal_code
)
SELECT DISTINCT
    raw.sale_customer_id::INTEGER,
    raw.customer_first_name,
    raw.customer_last_name,
    raw.customer_age::INTEGER,
    raw.customer_email,
    country.country_key,
    raw.customer_postal_code
FROM staging.mock_data raw
JOIN analytics.dim_country country
    ON country.country_name = raw.customer_country
ORDER BY raw.customer_email;

INSERT INTO analytics.dim_customer_pet (
    customer_key, pet_type_key, pet_breed_key, pet_name
)
SELECT DISTINCT
    customer.customer_key,
    pet_type.pet_type_key,
    pet_breed.pet_breed_key,
    raw.customer_pet_name
FROM staging.mock_data raw
JOIN analytics.dim_customer customer
    ON customer.email = raw.customer_email
JOIN analytics.dim_pet_type pet_type
    ON pet_type.pet_type_name = raw.customer_pet_type
JOIN analytics.dim_pet_breed pet_breed
    ON pet_breed.pet_breed_name = raw.customer_pet_breed
ORDER BY customer.customer_key;

INSERT INTO analytics.dim_seller (
    source_seller_id, first_name, last_name, email, country_key, postal_code
)
SELECT DISTINCT
    raw.sale_seller_id::INTEGER,
    raw.seller_first_name,
    raw.seller_last_name,
    raw.seller_email,
    country.country_key,
    raw.seller_postal_code
FROM staging.mock_data raw
JOIN analytics.dim_country country
    ON country.country_name = raw.seller_country
ORDER BY raw.seller_email;

INSERT INTO analytics.dim_product (
    source_product_id, product_name, product_category_key, pet_category_key,
    product_brand_key, product_material_key, unit_price, available_quantity,
    product_weight, product_color, product_size, product_description,
    product_rating, product_reviews, product_release_date, product_expiry_date
)
SELECT DISTINCT
    raw.sale_product_id::INTEGER,
    raw.product_name,
    product_category.product_category_key,
    pet_category.pet_category_key,
    brand.product_brand_key,
    material.product_material_key,
    raw.product_price::NUMERIC(12, 2),
    raw.product_quantity::INTEGER,
    raw.product_weight::NUMERIC(10, 2),
    raw.product_color,
    raw.product_size,
    raw.product_description,
    raw.product_rating::NUMERIC(3, 1),
    raw.product_reviews::INTEGER,
    to_date(raw.product_release_date, 'MM/DD/YYYY'),
    to_date(raw.product_expiry_date, 'MM/DD/YYYY')
FROM staging.mock_data raw
JOIN analytics.dim_product_category product_category
    ON product_category.product_category_name = raw.product_category
JOIN analytics.dim_pet_category pet_category
    ON pet_category.pet_category_name = raw.pet_category
JOIN analytics.dim_brand brand
    ON brand.product_brand_name = raw.product_brand
JOIN analytics.dim_material material
    ON material.product_material_name = raw.product_material
ORDER BY
    1,
    2,
    5,
    6;

INSERT INTO analytics.dim_store (
    store_name, store_location, store_city, store_state, country_key,
    store_phone, store_email
)
SELECT DISTINCT
    raw.store_name,
    raw.store_location,
    raw.store_city,
    raw.store_state,
    country.country_key,
    raw.store_phone,
    raw.store_email
FROM staging.mock_data raw
JOIN analytics.dim_country country
    ON country.country_name = raw.store_country
ORDER BY raw.store_email;

INSERT INTO analytics.dim_supplier (
    supplier_name, supplier_contact, supplier_email, supplier_phone,
    supplier_address, supplier_city, country_key
)
SELECT DISTINCT
    raw.supplier_name,
    raw.supplier_contact,
    raw.supplier_email,
    raw.supplier_phone,
    raw.supplier_address,
    raw.supplier_city,
    country.country_key
FROM staging.mock_data raw
JOIN analytics.dim_country country
    ON country.country_name = raw.supplier_country
ORDER BY raw.supplier_email;

INSERT INTO analytics.dim_date (
    date_key, year, quarter, month, day, day_of_week, day_name
)
SELECT DISTINCT
    sale_date::DATE AS date_key,
    EXTRACT(YEAR FROM sale_date)::SMALLINT AS year,
    EXTRACT(QUARTER FROM sale_date)::SMALLINT AS quarter,
    EXTRACT(MONTH FROM sale_date)::SMALLINT AS month,
    EXTRACT(DAY FROM sale_date)::SMALLINT AS day,
    EXTRACT(ISODOW FROM sale_date)::SMALLINT AS day_of_week,
    trim(to_char(sale_date, 'Day')) AS day_name
FROM (
    SELECT to_date(sale_date, 'MM/DD/YYYY') AS sale_date
    FROM staging.mock_data
) dates
ORDER BY date_key;

INSERT INTO analytics.fact_sales (
    raw_id, source_sale_id, customer_key, customer_pet_key, seller_key,
    product_key, store_key, supplier_key, sale_date_key, sale_quantity,
    sale_total_price
)
SELECT
    raw.raw_id,
    raw.id::INTEGER,
    customer.customer_key,
    customer_pet.customer_pet_key,
    seller.seller_key,
    product.product_key,
    store.store_key,
    supplier.supplier_key,
    to_date(raw.sale_date, 'MM/DD/YYYY'),
    raw.sale_quantity::INTEGER,
    raw.sale_total_price::NUMERIC(12, 2)
FROM staging.mock_data raw
JOIN analytics.dim_customer customer
    ON customer.email = raw.customer_email
JOIN analytics.dim_customer_pet customer_pet
    ON customer_pet.customer_key = customer.customer_key
JOIN analytics.dim_pet_type pet_type
    ON pet_type.pet_type_key = customer_pet.pet_type_key
    AND pet_type.pet_type_name = raw.customer_pet_type
JOIN analytics.dim_pet_breed pet_breed
    ON pet_breed.pet_breed_key = customer_pet.pet_breed_key
    AND pet_breed.pet_breed_name = raw.customer_pet_breed
    AND customer_pet.pet_name = raw.customer_pet_name
JOIN analytics.dim_seller seller
    ON seller.email = raw.seller_email
JOIN analytics.dim_product product
    ON product.source_product_id = raw.sale_product_id::INTEGER
    AND product.product_name = raw.product_name
    AND product.unit_price = raw.product_price::NUMERIC(12, 2)
    AND product.available_quantity = raw.product_quantity::INTEGER
    AND product.product_weight = raw.product_weight::NUMERIC(10, 2)
    AND product.product_color = raw.product_color
    AND product.product_size = raw.product_size
    AND product.product_description = raw.product_description
    AND product.product_rating = raw.product_rating::NUMERIC(3, 1)
    AND product.product_reviews = raw.product_reviews::INTEGER
    AND product.product_release_date = to_date(raw.product_release_date, 'MM/DD/YYYY')
    AND product.product_expiry_date = to_date(raw.product_expiry_date, 'MM/DD/YYYY')
JOIN analytics.dim_product_category product_category
    ON product_category.product_category_key = product.product_category_key
    AND product_category.product_category_name = raw.product_category
JOIN analytics.dim_pet_category pet_category
    ON pet_category.pet_category_key = product.pet_category_key
    AND pet_category.pet_category_name = raw.pet_category
JOIN analytics.dim_brand brand
    ON brand.product_brand_key = product.product_brand_key
    AND brand.product_brand_name = raw.product_brand
JOIN analytics.dim_material material
    ON material.product_material_key = product.product_material_key
    AND material.product_material_name = raw.product_material
JOIN analytics.dim_store store
    ON store.store_email = raw.store_email
JOIN analytics.dim_supplier supplier
    ON supplier.supplier_email = raw.supplier_email
ORDER BY raw.raw_id;
