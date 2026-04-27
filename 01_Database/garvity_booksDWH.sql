
CREATE DATABASE GravityBookstore_DWH;
GO
USE GravityBookstore_DWH;
GO
-- =============================================
-- DIM_DATE
-- =============================================
CREATE TABLE Dim_Date (
    date_SK     INT          NOT NULL PRIMARY KEY,
    full_date   DATE         NOT NULL,
    day         TINYINT      NOT NULL,
    day_of_week TINYINT      NOT NULL,
    day_name    NVARCHAR(10) NOT NULL,
    month       TINYINT      NOT NULL,
    month_name  NVARCHAR(10) NOT NULL,
    quarter     TINYINT      NOT NULL,
    year        SMALLINT     NOT NULL,
    is_weekend  BIT          NOT NULL DEFAULT 0
);

-- =============================================
-- DIM_TIME
-- =============================================
CREATE TABLE Dim_Time (
    time_SK        INT         NOT NULL IDENTITY(1,1) PRIMARY KEY,
    time           TIME(0)     NOT NULL,
    hour           CHAR(2)     NOT NULL,
    military_hour  CHAR(2)     NOT NULL,
    minute         CHAR(2)     NOT NULL,
    second         CHAR(2)     NOT NULL,
    am_pm          CHAR(2)     NOT NULL,
    standard_time  CHAR(11)    NULL,
    shift          VARCHAR(10) NULL
);
-- =============================================
-- DIM_CUSTOMER (SCD Type 2)
-- =============================================
CREATE TABLE Dim_Customer (
    customer_SK INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    customer_NK INT           NOT NULL,
    first_name  NVARCHAR(200) NOT NULL,
    last_name   NVARCHAR(200) NOT NULL,
    full_name   AS (first_name + ' ' + last_name) PERSISTED,
    email       NVARCHAR(350) NULL,
    start_date  DATE          NOT NULL DEFAULT GETDATE(),
    end_date    DATE          NULL,
    is_current  BIT           NOT NULL DEFAULT 1
);
CREATE INDEX IX_DimCustomer_NK ON Dim_Customer (customer_NK, is_current);

-- =============================================
-- DIM_BOOK (SCD Type 1)
-- =============================================
CREATE TABLE Dim_Book (
    book_SK            INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    book_NK            INT           NOT NULL,
    source_system_code NVARCHAR(10)  NOT NULL DEFAULT 'GB',
    title              NVARCHAR(400) NOT NULL,
    isbn13             VARCHAR(20)   NULL,
    num_pages          INT           NULL,
    publication_date   DATE          NULL,
    publication_year   AS (YEAR(publication_date)) PERSISTED,
    language_code      VARCHAR(10)   NULL,
    language_name      NVARCHAR(100) NULL,
    publisher_name     NVARCHAR(400) NULL
);
CREATE UNIQUE INDEX IX_DimBook_NK ON Dim_Book (book_NK);

-- =============================================
-- DIM_AUTHOR (SCD Type 1)
-- =============================================
CREATE TABLE Dim_Author (
    author_SK   INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    author_NK   INT           NOT NULL,
    author_name NVARCHAR(200) NOT NULL
);
CREATE UNIQUE INDEX IX_DimAuthor_NK ON Dim_Author (author_NK);

-- =============================================
-- DIM_SHIPPING_METHOD (SCD Type 1)
-- =============================================
CREATE TABLE Dim_ShippingMethod (
    shipping_method_SK INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    method_NK          INT           NOT NULL,
    method_name        NVARCHAR(100) NOT NULL,
    cost               DECIMAL(10,2) NULL
);
CREATE UNIQUE INDEX IX_DimShipping_NK ON Dim_ShippingMethod (method_NK);

-- =============================================
-- DIM_ADDRESS (SCD Type 1)
-- =============================================
CREATE TABLE Dim_Address (
    address_SK         INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    address_NK         INT           NOT NULL,
    source_system_code NVARCHAR(10)  NOT NULL DEFAULT 'GB',
    street_number      NVARCHAR(20)  NULL,
    street_name        NVARCHAR(200) NULL,
    city               NVARCHAR(100) NULL,
    country_name       NVARCHAR(200) NULL
);
CREATE UNIQUE INDEX IX_DimAddress_NK ON Dim_Address (address_NK);

-- =============================================
-- DIM_ORDER_STATUS (SCD Type 1)
-- =============================================
CREATE TABLE Dim_OrderStatus (
    order_status_SK INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    status_NK       INT           NOT NULL,
    status_value    NVARCHAR(100) NOT NULL
);
CREATE UNIQUE INDEX IX_DimStatus_NK ON Dim_OrderStatus (status_NK);

-- =============================================
-- BRIDGE_BOOK_AUTHOR
-- =============================================
CREATE TABLE Bridge_BookAuthor (
    book_SK          INT          NOT NULL,
    author_SK        INT          NOT NULL,
    weighting_factor DECIMAL(5,4) NOT NULL,
    CONSTRAINT PK_Bridge_BookAuthor
        PRIMARY KEY (book_SK, author_SK),
    CONSTRAINT FK_Bridge_Book
        FOREIGN KEY (book_SK)   REFERENCES Dim_Book(book_SK),
    CONSTRAINT FK_Bridge_Author
        FOREIGN KEY (author_SK) REFERENCES Dim_Author(author_SK)
);

-- =============================================
-- BRIDGE_CUSTOMER_ADDRESS (SCD Type 2)
-- =============================================
CREATE TABLE Bridge_CustomerAddress (
    customer_SK INT  NOT NULL,
    address_SK  INT  NOT NULL,
    start_date  DATE NOT NULL DEFAULT GETDATE(),
    end_date    DATE NULL,
    is_current  BIT  NOT NULL DEFAULT 1,
    CONSTRAINT PK_Bridge_CustomerAddress
        PRIMARY KEY (customer_SK, address_SK),
    CONSTRAINT FK_BCA_Customer
        FOREIGN KEY (customer_SK) REFERENCES Dim_Customer(customer_SK),
    CONSTRAINT FK_BCA_Address
        FOREIGN KEY (address_SK)  REFERENCES Dim_Address(address_SK)
);

-- =============================================
-- FACT_BOOK_SALES
-- =============================================
CREATE TABLE Fact_BookSales (
    sale_SK            INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    date_SK            INT           NOT NULL,
    time_SK            INT           NULL,
    customer_SK        INT           NOT NULL,
    book_SK            INT           NOT NULL,
    shipping_method_SK INT           NOT NULL,
    address_SK         INT           NOT NULL,
    order_number       INT           NOT NULL,
    line_id            INT           NOT NULL,
    sale_price         DECIMAL(10,2) NOT NULL,
    quantity           INT           NOT NULL DEFAULT 1,
    line_total         AS (sale_price * quantity) PERSISTED,
    shipping_cost      DECIMAL(10,2) NULL,
    CONSTRAINT FK_Sales_Date
        FOREIGN KEY (date_SK)            REFERENCES Dim_Date(date_SK),
    CONSTRAINT FK_Sales_Time
        FOREIGN KEY (time_SK) REFERENCES Dim_Time(Time_SK),
    CONSTRAINT FK_Sales_Customer
        FOREIGN KEY (customer_SK)        REFERENCES Dim_Customer(customer_SK),
    CONSTRAINT FK_Sales_Book
        FOREIGN KEY (book_SK)            REFERENCES Dim_Book(book_SK),
    CONSTRAINT FK_Sales_Shipping
        FOREIGN KEY (shipping_method_SK) REFERENCES Dim_ShippingMethod(shipping_method_SK),
    CONSTRAINT FK_Sales_Address
        FOREIGN KEY (address_SK)         REFERENCES Dim_Address(address_SK)
);
CREATE NONCLUSTERED INDEX IX_FactSales_Date     ON Fact_BookSales (date_SK);
CREATE NONCLUSTERED INDEX IX_FactSales_Time     ON Fact_BookSales (time_SK);
CREATE NONCLUSTERED INDEX IX_FactSales_Customer ON Fact_BookSales (customer_SK);
CREATE NONCLUSTERED INDEX IX_FactSales_Book     ON Fact_BookSales (book_SK);

-- =============================================
-- FACT_ORDER_HISTORY
-- =============================================
CREATE TABLE Fact_OrderHistory (
    history_SK      INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    status_date_SK  INT NOT NULL,
    status_time_SK  INT NULL,
    customer_SK     INT NOT NULL,
    order_status_SK INT NOT NULL,
    order_number    INT NOT NULL,
    days_to_status  INT NULL,
    CONSTRAINT FK_History_Date
        FOREIGN KEY (status_date_SK)  REFERENCES Dim_Date(date_SK),
    CONSTRAINT FK_History_Time
        FOREIGN KEY (status_time_SK) REFERENCES Dim_Time(Time_SK),
    CONSTRAINT FK_History_Customer
        FOREIGN KEY (customer_SK)     REFERENCES Dim_Customer(customer_SK),
    CONSTRAINT FK_History_Status
        FOREIGN KEY (order_status_SK) REFERENCES Dim_OrderStatus(order_status_SK)
);
CREATE NONCLUSTERED INDEX IX_FactHistory_Date  ON Fact_OrderHistory (status_date_SK);
CREATE NONCLUSTERED INDEX IX_FactHistory_Order ON Fact_OrderHistory (order_number);

PRINT 'DWH Database Created Successfully at: ' + CONVERT(varchar, GETDATE(), 113);