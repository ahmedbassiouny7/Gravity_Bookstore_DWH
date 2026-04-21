# 📚 Gravity Bookstore — Data Warehouse Project

> An end-to-end Data Warehouse solution built on SQL Server, SSIS, SSAS, and Power BI — implementing a full Medallion-style ETL pipeline with a dimensional model, incremental loads, SCD handling, and an analytical cube.

---

## 🗂️ Table of Contents

- [Project Overview](#-project-overview)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Dimensional Model](#-dimensional-model)
- [Repository Structure](#-repository-structure)
- [Setup Guide](#-setup-guide)
- [ETL Pipeline](#-etl-pipeline)
- [Data Dictionary](#-data-dictionary)
- [SSAS Cube](#-ssas-cube)
- [Power BI Dashboards](#-power-bi-dashboards)
- [Key Design Decisions](#-key-design-decisions)
- [Author](#-author)

---

## 📌 Project Overview

**Gravity Bookstore DWH** is a complete data warehousing solution built as a graduation project. It ingests transactional data from an OLTP bookstore database, transforms and loads it into a dimensional data warehouse, and exposes it through an SSAS multidimensional cube and Power BI dashboards.

### Business Questions Answered
- What are the total sales and revenue trends over time?
- Who are the top customers and which books drive the most revenue?
- How long does order fulfillment take across different shipping methods?
- Which authors, publishers, and languages generate the most sales?
- How do customer addresses and relationships change over time?

### Project Scope

| Component | Details |
|---|---|
| Source System | `gravity_books` — SQL Server OLTP database |
| Staging Layer | `GravityBookstore_Staging` — full load, truncate + insert |
| Data Warehouse | `GravityBookstore_DWH` — star schema with SCD support |
| ETL Tool | SSIS (SQL Server Integration Services) |
| Analytical Layer | SSAS Multidimensional Cube |
| Reporting Layer | Power BI Desktop |

---

## 🛠️ Tech Stack

| Tool | Version | Purpose |
|---|---|---|
| SQL Server | 2022 | OLTP source + DWH storage |
| SSIS | Visual Studio 2022 | ETL pipeline |
| SSAS | Multidimensional mode | Analytical cube |
| Power BI Desktop | Latest | Dashboards & reporting |
| T-SQL | — | DDL, stored procedures, bridge logic |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        SOURCE LAYER                          │
│                  gravity_books (OLTP)                        │
│     Books │ Authors │ Customers │ Orders │ Addresses         │
└─────────────────────┬───────────────────────────────────────┘
                      │  01_Staging_Load.dtsx
                      │  Full Load (Truncate + Insert)
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                      STAGING LAYER                           │
│             GravityBookstore_Staging                         │
│   15 staging tables — exact mirror of OLTP                  │
└─────────────────────┬───────────────────────────────────────┘
                      │  02_Dim_Load.dtsx
                      │  Incremental Load (Lookup + SCD)
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATA WAREHOUSE LAYER                      │
│               GravityBookstore_DWH                          │
│   Dim Tables │ Fact Tables │ Bridge Tables                   │
└─────────────────────┬───────────────────────────────────────┘
                      │  SSAS Multidimensional Cube
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│                Power BI Dashboards                           │
│  Sales │ Customers │ Order Status │ Book Performance         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📐 Dimensional Model

### Fact Tables

**Fact_BookSales** — Grain: one row per book line item per order

| Column | Type | Description |
|---|---|---|
| sale_SK | INT PK | Surrogate key |
| date_SK | INT FK | → Dim_Date |
| time_SK | INT NULL | → Dim_Time (nullable — no time in source) |
| customer_SK | INT FK | → Dim_Customer |
| book_SK | INT FK | → Dim_Book |
| shipping_method_SK | INT FK | → Dim_ShippingMethod |
| address_SK | INT FK | → Dim_Address |
| order_number | INT | Degenerate dimension |
| line_id | INT | Degenerate dimension |
| sale_price | DECIMAL(10,2) | Measure |
| quantity | INT | Measure |
| line_total | DECIMAL(10,2) | Computed measure |
| shipping_cost | DECIMAL(10,2) | Measure |

**Fact_OrderHistory** — Grain: one row per order status change

| Column | Type | Description |
|---|---|---|
| history_SK | INT PK | Surrogate key |
| status_date_SK | INT FK | → Dim_Date |
| status_time_SK | INT NULL | → Dim_Time (nullable) |
| customer_SK | INT FK | → Dim_Customer |
| order_status_SK | INT FK | → Dim_OrderStatus |
| order_number | INT | Degenerate dimension |
| days_to_status | INT | Measure |

### Dimension Tables

| Dimension | SCD Type | Key Columns | Notes |
|---|---|---|---|
| Dim_Date | Static | date_SK, full_date | Populated 2000–2030 |
| Dim_Time | Static | time_SK, Time | 86,400 rows (every second) |
| Dim_Customer | SCD Type 2 | customer_SK, customer_NK | Tracks email changes |
| Dim_Book | SCD Type 1 | book_SK, book_NK | `publication_year` is computed |
| Dim_Author | SCD Type 1 | author_SK, author_NK | — |
| Dim_Address | SCD Type 1 | address_SK, address_NK | — |
| Dim_ShippingMethod | SCD Type 1 | shipping_method_SK, method_NK | — |
| Dim_OrderStatus | SCD Type 1 | order_status_SK, status_NK | — |

### Bridge Tables

| Bridge | Purpose | Notes |
|---|---|---|
| Bridge_BookAuthor | Many-to-many books ↔ authors | Includes `weighting_factor` = 1/author_count |
| Bridge_CustomerAddress | Many-to-many customers ↔ addresses | SCD Type 2 with `bridge_SK` PK |

---

## 📁 Repository Structure

```
gravity-bookstore-dwh/
│
├── 📁 01_Database/
│   ├── 01_OLTP_Schema.sql          # Source database DDL (reference only)
│   ├── 02_Staging_DDL.sql          # GravityBookstore_Staging DDL
│   └── 03_DWH_DDL.sql              # GravityBookstore_DWH DDL
│
├── 📁 02_SSIS/
│   ├── 01_Staging_Load.dtsx        # Full staging load package
│   ├── 02_Dim_Load.dtsx            # Incremental dimension load
│   ├── 03_Fact_Load.dtsx           # Fact table load
│   └── 00_Master_Package.dtsx      # Master orchestration package
│
├── 📁 03_SSAS/
│   └── GravityBookstore_SSAS/      # SSAS Multidimensional project
│
├── 📁 04_PowerBI/
│   └── GravityBookstore.pbix       # Power BI report file
│
├── 📁 05_Documentation/
│   ├── Architecture_Diagram.png    # Full architecture diagram
│   ├── Dimensional_Model_ERD.png   # Star schema ERD
│   └── Data_Dictionary.md          # Full data dictionary
│
├── 📁 06_Screenshots/
│   ├── SSIS_Staging_Load.png
│   ├── SSIS_Dim_Load.png
│   ├── SSIS_Fact_Load.png
│   ├── SSAS_Cube_Browser.png
│   └── PowerBI_Dashboard.png
│
└── README.md
```

---

## ⚙️ Setup Guide

### Prerequisites

- SQL Server 2022
- Visual Studio 2022 with SSIS & SSAS extensions
- SQL Server Analysis Services (Multidimensional mode instance)
- Power BI Desktop

### Step 1 — Restore Source Database

```sql
-- Restore or create gravity_books OLTP database
-- Script: 01_Database/01_OLTP_Schema.sql
```

### Step 2 — Create Staging & DWH Databases

```sql
-- Run in order:
-- 01_Database/02_Staging_DDL.sql
-- 01_Database/03_DWH_DDL.sql
```

### Step 3 — Configure SSIS Connection Managers

Open each `.dtsx` package and update the connection managers:

| Connection Manager | Points To |
|---|---|
| CM_OLTP | Your SQL Server → `gravity_books` |
| CM_Staging | Your SQL Server → `GravityBookstore_Staging` |
| CM_DWH | Your SQL Server → `GravityBookstore_DWH` |

### Step 4 — Run ETL Packages

Execute in this order (or use the Master Package):

```
00_Master_Package.dtsx
    ├── 01_Staging_Load.dtsx   ← truncates + reloads staging
    ├── 02_Dim_Load.dtsx       ← incremental dim load with SCD
    └── 03_Fact_Load.dtsx      ← fact load with SK lookups
```

### Step 5 — Deploy SSAS Cube

1. Open `03_SSAS/GravityBookstore_SSAS.sln` in Visual Studio
2. Update Data Source connection to your SQL Server
3. Set Deployment Server to your SSAS Multidimensional instance
4. Right-click project → Deploy
5. Right-click cube → Process

### Step 6 — Open Power BI Report

1. Open `04_PowerBI/GravityBookstore.pbix`
2. Update the data source to point to your SSAS instance
3. Refresh the report

---

## 🔄 ETL Pipeline

### Package 01 — Staging Load
- **Strategy:** Full Load (Truncate + Insert)
- **Method:** Single Execute SQL Task with multi-statement T-SQL
- **Row counts after load:**

| Table | Rows |
|---|---|
| stg_book | 11,127 |
| stg_author | 9,235 |
| stg_book_author | 17,642 |
| stg_customer | 2,000 |
| stg_address | 1,000 |
| stg_cust_order | 7,550 |
| stg_order_line | 15,400 |
| stg_order_history | 22,344 |

### Package 02 — Dim Load
- **Strategy:** Incremental Load
- **SCD1 pattern:** OLE DB Source → Lookup → Conditional Split → INSERT new / UPDATE changed
- **SCD2 pattern (Dim_Customer):** SSIS SCD Wizard — expires old rows, inserts new versions
- **Bridges:** Execute SQL Tasks using T-SQL MERGE-style logic

### Package 03 — Fact Load
- **Strategy:** Incremental Load
- **Pattern:** OLE DB Source → chain of Lookups (one per dimension) → OLE DB Destination
- **SK resolution:** Each Lookup replaces NK with SK from the corresponding dimension

---

## 📖 Data Dictionary

### Dim_Customer

| Column | Type | Nullable | Description |
|---|---|---|---|
| customer_SK | INT | NO | Surrogate key (IDENTITY) |
| customer_NK | INT | NO | Natural key from source |
| first_name | VARCHAR(100) | NO | Customer first name |
| last_name | VARCHAR(100) | NO | Customer last name |
| full_name | VARCHAR(201) | — | Computed: first_name + ' ' + last_name |
| email | VARCHAR(200) | YES | Customer email (SCD2 tracked) |
| source_system_code | VARCHAR(10) | YES | Source system identifier ('GB') |
| start_date | DATE | NO | Record effective start date |
| end_date | DATE | YES | Record expiry date (NULL = current) |
| is_current | BIT | NO | 1 = current record, 0 = expired |

### Dim_Book

| Column | Type | Nullable | Description |
|---|---|---|---|
| book_SK | INT | NO | Surrogate key (IDENTITY) |
| book_NK | INT | NO | Natural key from source |
| source_system_code | VARCHAR(10) | YES | Source system identifier ('GB') |
| title | NVARCHAR(400) | NO | Book title |
| isbn13 | VARCHAR(20) | YES | ISBN-13 |
| num_pages | INT | YES | Number of pages |
| publication_date | DATE | YES | Publication date |
| publication_year | INT | — | Computed: YEAR(publication_date) |
| language_code | VARCHAR(10) | YES | Language code |
| language_name | VARCHAR(100) | YES | Language name |
| publisher_name | VARCHAR(400) | YES | Publisher name |

### Bridge_BookAuthor

| Column | Type | Nullable | Description |
|---|---|---|---|
| book_SK | INT | NO | FK → Dim_Book |
| author_SK | INT | NO | FK → Dim_Author |
| weighting_factor | DECIMAL(5,4) | NO | 1 / number of authors for the book |

---

## 🧊 SSAS Cube

### Cube: GravityBookstore_Cube

| Measure Group | Measures |
|---|---|
| Fact Book Sales | Sale Price (Sum), Shipping Cost (Sum), Quantity (Sum), Line Total (Sum), Count |
| Fact Order History | Days To Status (Avg), Count |

### Dimensions

| Dimension | Type | Key Attribute |
|---|---|---|
| Dim Date | Time | Date SK |
| Dim Customer | Regular | Customer SK |
| Dim Book | Regular | Book SK |
| Dim Author | Regular | Author SK |
| Dim Address | Regular | Address SK |
| Dim Shipping Method | Regular | Shipping Method SK |
| Dim Order Status | Regular | Order Status SK |

---

## 📊 Power BI Dashboards

The report consists of 4 pages connected live to the SSAS cube:

| Page | Key Visuals |
|---|---|
| Sales Overview | Revenue KPIs, sales trend, top books, sales by shipping method |
| Customer Analysis | Top customers, customers by country, order distribution |
| Order Status | Order funnel, avg days to delivery, status trends |
| Book Performance | Top books/authors, sales by language, top publishers |

---

## 💡 Key Design Decisions

**Why Surrogate Keys?**
Surrogate keys (IDENTITY columns) decouple the DWH from the source system. If the source system changes its IDs, the DWH is unaffected.

**Why SCD Type 2 for Dim_Customer?**
Customer email changes are business-significant — we need to know what email a customer had at the time of purchase for historical accuracy.

**Why Bridge Tables?**
Books can have multiple authors (many-to-many). The `weighting_factor` in Bridge_BookAuthor allows proportional attribution of sales to each author.

**Why Staging Layer?**
The staging layer protects the OLTP system from heavy ETL queries, provides a recovery point if the load fails midway, and decouples source system changes from DWH logic.

**Why time_SK is nullable in Fact Tables?**
The source system only stores order dates — no time component. Storing `00:00:00` would be misleading, so `time_SK` is nullable rather than forced to a fake default.

---

## 👤 Author

**Ahmed Bassiouny**
Data Engineering Student

[![GitHub](https://img.shields.io/badge/GitHub-7absy-black?logo=github)](https://github.com/7absy)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?logo=linkedin)](https://www.linkedin.com/in/ahmed-bassiouny-8966a3184/)

---

> ⭐ If you found this project useful, consider giving it a star!
