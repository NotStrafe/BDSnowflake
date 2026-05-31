DROP TABLE IF EXISTS analytics.fact_sales;
DROP TABLE IF EXISTS analytics.dim_date;
DROP TABLE IF EXISTS analytics.dim_customer_pet;
DROP TABLE IF EXISTS analytics.dim_customer;
DROP TABLE IF EXISTS analytics.dim_seller;
DROP TABLE IF EXISTS analytics.dim_product;
DROP TABLE IF EXISTS analytics.dim_supplier;
DROP TABLE IF EXISTS analytics.dim_store;
DROP TABLE IF EXISTS analytics.dim_pet_type;
DROP TABLE IF EXISTS analytics.dim_pet_breed;
DROP TABLE IF EXISTS analytics.dim_product_category;
DROP TABLE IF EXISTS analytics.dim_pet_category;
DROP TABLE IF EXISTS analytics.dim_brand;
DROP TABLE IF EXISTS analytics.dim_material;
DROP TABLE IF EXISTS analytics.dim_country;

CREATE TABLE analytics.dim_country (
    country_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_name TEXT NOT NULL UNIQUE
);

CREATE TABLE analytics.dim_pet_type (
    pet_type_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_type_name TEXT NOT NULL UNIQUE
);

CREATE TABLE analytics.dim_pet_breed (
    pet_breed_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_breed_name TEXT NOT NULL UNIQUE
);

CREATE TABLE analytics.dim_product_category (
    product_category_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_category_name TEXT NOT NULL UNIQUE
);

CREATE TABLE analytics.dim_pet_category (
    pet_category_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_category_name TEXT NOT NULL UNIQUE
);

CREATE TABLE analytics.dim_brand (
    product_brand_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_brand_name TEXT NOT NULL UNIQUE
);

CREATE TABLE analytics.dim_material (
    product_material_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_material_name TEXT NOT NULL UNIQUE
);

CREATE TABLE analytics.dim_customer (
    customer_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_customer_id INTEGER NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    age INTEGER NOT NULL,
    email TEXT NOT NULL UNIQUE,
    country_key BIGINT NOT NULL REFERENCES analytics.dim_country(country_key),
    postal_code TEXT
);

CREATE TABLE analytics.dim_customer_pet (
    customer_pet_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_key BIGINT NOT NULL REFERENCES analytics.dim_customer(customer_key),
    pet_type_key BIGINT NOT NULL REFERENCES analytics.dim_pet_type(pet_type_key),
    pet_breed_key BIGINT NOT NULL REFERENCES analytics.dim_pet_breed(pet_breed_key),
    pet_name TEXT NOT NULL,
    UNIQUE (customer_key, pet_type_key, pet_breed_key, pet_name)
);

CREATE TABLE analytics.dim_seller (
    seller_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_seller_id INTEGER NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    country_key BIGINT NOT NULL REFERENCES analytics.dim_country(country_key),
    postal_code TEXT
);

CREATE TABLE analytics.dim_product (
    product_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_product_id INTEGER NOT NULL,
    product_name TEXT NOT NULL,
    product_category_key BIGINT NOT NULL REFERENCES analytics.dim_product_category(product_category_key),
    pet_category_key BIGINT NOT NULL REFERENCES analytics.dim_pet_category(pet_category_key),
    product_brand_key BIGINT NOT NULL REFERENCES analytics.dim_brand(product_brand_key),
    product_material_key BIGINT NOT NULL REFERENCES analytics.dim_material(product_material_key),
    unit_price NUMERIC(12, 2) NOT NULL,
    available_quantity INTEGER NOT NULL,
    product_weight NUMERIC(10, 2) NOT NULL,
    product_color TEXT NOT NULL,
    product_size TEXT NOT NULL,
    product_description TEXT NOT NULL,
    product_rating NUMERIC(3, 1) NOT NULL,
    product_reviews INTEGER NOT NULL,
    product_release_date DATE NOT NULL,
    product_expiry_date DATE NOT NULL
);

CREATE TABLE analytics.dim_store (
    store_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    store_name TEXT NOT NULL,
    store_location TEXT NOT NULL,
    store_city TEXT NOT NULL,
    store_state TEXT,
    country_key BIGINT NOT NULL REFERENCES analytics.dim_country(country_key),
    store_phone TEXT NOT NULL,
    store_email TEXT NOT NULL UNIQUE
);

CREATE TABLE analytics.dim_supplier (
    supplier_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_name TEXT NOT NULL,
    supplier_contact TEXT NOT NULL,
    supplier_email TEXT NOT NULL UNIQUE,
    supplier_phone TEXT NOT NULL,
    supplier_address TEXT NOT NULL,
    supplier_city TEXT NOT NULL,
    country_key BIGINT NOT NULL REFERENCES analytics.dim_country(country_key)
);

CREATE TABLE analytics.dim_date (
    date_key DATE PRIMARY KEY,
    year SMALLINT NOT NULL,
    quarter SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    day SMALLINT NOT NULL,
    day_of_week SMALLINT NOT NULL,
    day_name TEXT NOT NULL
);

CREATE TABLE analytics.fact_sales (
    sale_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    raw_id BIGINT NOT NULL REFERENCES staging.mock_data(raw_id),
    source_sale_id INTEGER NOT NULL,
    customer_key BIGINT NOT NULL REFERENCES analytics.dim_customer(customer_key),
    customer_pet_key BIGINT NOT NULL REFERENCES analytics.dim_customer_pet(customer_pet_key),
    seller_key BIGINT NOT NULL REFERENCES analytics.dim_seller(seller_key),
    product_key BIGINT NOT NULL REFERENCES analytics.dim_product(product_key),
    store_key BIGINT NOT NULL REFERENCES analytics.dim_store(store_key),
    supplier_key BIGINT NOT NULL REFERENCES analytics.dim_supplier(supplier_key),
    sale_date_key DATE NOT NULL REFERENCES analytics.dim_date(date_key),
    sale_quantity INTEGER NOT NULL,
    sale_total_price NUMERIC(12, 2) NOT NULL
);

CREATE INDEX idx_fact_sales_customer ON analytics.fact_sales(customer_key);
CREATE INDEX idx_fact_sales_seller ON analytics.fact_sales(seller_key);
CREATE INDEX idx_fact_sales_product ON analytics.fact_sales(product_key);
CREATE INDEX idx_fact_sales_store ON analytics.fact_sales(store_key);
CREATE INDEX idx_fact_sales_supplier ON analytics.fact_sales(supplier_key);
CREATE INDEX idx_fact_sales_date ON analytics.fact_sales(sale_date_key);
