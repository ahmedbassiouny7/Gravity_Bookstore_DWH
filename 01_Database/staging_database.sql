CREATE DATABASE GravityBookstore_Staging;
GO
USE GravityBookstore_Staging;
GO

CREATE TABLE stg_book (
    book_id          INT,
    title            NVARCHAR(400),
    isbn13           VARCHAR(20),
    language_id      INT,
    num_pages        INT,
    publication_date DATE,
    publisher_id     INT,
    _load_date       DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_author (
    author_id   INT,
    author_name NVARCHAR(200),
    _load_date  DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_book_author (
    book_id    INT,
    author_id  INT,
    _load_date DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_book_language (
    language_id   INT,
    language_code VARCHAR(10),
    language_name NVARCHAR(100),
    _load_date    DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_publisher (
    publisher_id   INT,
    publisher_name NVARCHAR(400),
    _load_date     DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_customer (
    customer_id INT,
    first_name  NVARCHAR(200),
    last_name   NVARCHAR(200),
    email       NVARCHAR(350),
    _load_date  DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_address (
    address_id    INT,
    street_number NVARCHAR(20),
    street_name   NVARCHAR(200),
    city          NVARCHAR(100),
    country_id    INT,
    _load_date    DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_country (
    country_id   INT,
    country_name NVARCHAR(200),
    _load_date   DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_customer_address (
    customer_id INT,
    address_id  INT,
    status_id   INT,
    _load_date  DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_address_status (
    status_id      INT,
    address_status NVARCHAR(50),
    _load_date     DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_shipping_method (
    method_id   INT,
    method_name NVARCHAR(100),
    cost        DECIMAL(10,2),
    _load_date  DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_order_status (
    status_id    INT,
    status_value NVARCHAR(100),
    _load_date   DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_cust_order (
    order_id           INT,
    order_date         DATETIME,
    customer_id        INT,
    shipping_method_id INT,
    dest_address_id    INT,
    _load_date         DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_order_line (
    line_id    INT,
    order_id   INT,
    book_id    INT,
    price      DECIMAL(10,2),
    _load_date DATETIME DEFAULT GETDATE()
);

CREATE TABLE stg_order_history (
    history_id  INT,
    order_id    INT,
    status_id   INT,
    status_date DATETIME,
    _load_date  DATETIME DEFAULT GETDATE()
);

CREATE TABLE etl_error_log (
    log_id        INT           IDENTITY(1,1) PRIMARY KEY,
    package_name  NVARCHAR(100),
    error_message NVARCHAR(MAX),
    error_time    DATETIME DEFAULT GETDATE()
);