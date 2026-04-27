# 📚 Gravity Bookstore — Data Warehouse Project

![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC2927?logo=microsoftsqlserver&logoColor=white)
![SSIS](https://img.shields.io/badge/SSIS-Visual%20Studio%202022-5C2D91?logo=visualstudio&logoColor=white)
![SSAS](https://img.shields.io/badge/SSAS-Multidimensional-0078D4?logo=microsoft&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/Status-Completed-27AE60)

> An end-to-end Data Warehouse solution built on SQL Server, SSIS, SSAS, and Power BI — implementing a full ETL pipeline with a dimensional model, incremental loads, SCD handling, and an analytical cube.

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
- [Key Findings](#-key-findings)
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
| Data Warehouse | `GravityBookstore_DWH` — snowflake schema with SCD support |
| ETL Tool | SSIS (SQL Server Integration Services) |
| Analytical Layer | SSAS Multidimensional Cube |
| Reporting Layer | Power BI Desktop (live connection to SSAS) |

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
│               GravityBookstore_DWH                           │
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
retail-analytics-platform/
│
├── 📁 01_Database/
│   ├── 01_OLTP_Schema.sql              # Source database DDL (reference only)
│   ├── 02_Staging_DDL.sql              # GravityBookstore_Staging DDL
│   └── 03_DWH_DDL.sql                  # GravityBookstore_DWH DDL
│
├── 📁 02_SSIS/
│   ├── 00_Master_Package.dtsx          # Master orchestration package
│   ├── 01_Staging_Load.dtsx            # Full staging load package
│   ├── 02_Dim_Load.dtsx                # Incremental dimension load
│   └── 03_Fact_Load.dtsx               # Fact table load
│
├── 📁 03_SSAS/
│   ├── GravityBookstore_SSAS.dwproj    # Main VS project file
│   ├── GravityBookstore_Cube.cube      # Cube definition (measures, KPIs, MDX)
│   ├── GravityBookstore_DSV.dsv        # Data Source View
│   ├── GravityBookstore_DWH.ds         # Data source connection
│   ├── GravityBookstore_Cube.database  # Database definition
│   ├── GravityBookstore_Cube.partitions# Partition definitions
│   └── Dim *.dim (×6)                  # All dimension definitions
│
├── 📁 04_PowerBI/
│   ├── GravityBookstore.pbix           # Power BI report file
│   └── GravityBookstore_Theme.json     # Custom theme file
│
├── 📁 05_Dashboard/
│   └── GravityBookstore_Dashboard.html # Interactive HTML dashboard
│
├── 📁 06_Documentation/
│   ├── Architecture_Diagram.png        # Full architecture diagram
│   ├── Dimensional_Model_ERD.png       # snowflake schema ERD
│   └── Data_Dictionary.md              # Full data dictionary
│
├── 📁 07_Screenshots/
│   ├── 01_SSIS_Staging_Load.png
│   ├── 02_SSIS_Dim_Load.png
│   ├── 03_SSIS_Fact_Load.png
│   ├── 04_SSAS_Cube_Browser.png
│   └── 05_PowerBI_Dashboard.png
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

1. Open `03_SSAS/GravityBookstore_SSAS.dwproj` in Visual Studio
2. Update Data Source connection to your SQL Server
3. Set Deployment Server to your SSAS Multidimensional instance (`localhost\SSAS_MD`)
4. Right-click project → **Deploy**
5. Right-click cube → **Process**

### Step 6 — Open Power BI Report

1. Open `04_PowerBI/GravityBookstore.pbix`
2. Update the data source to point to your SSAS instance
3. Refresh the report

---

## 🔄 ETL Pipeline

### Package 01 — Staging Load

- **Strategy:** Full Load (Truncate + Insert)
- **Method:** OLE DB Source → OLE DB Destination per table

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
- **SCD Type 1 pattern:** OLE DB Source → Lookup → Conditional Split → INSERT new / UPDATE changed
- **SCD Type 2 pattern (Dim_Customer):** SSIS SCD Wizard — expires old rows, inserts new versions
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

**Cube:** `GravityBookstore_Cube` | **Instance:** `localhost\SSAS_MD`

| Measure Group | Measures |
|---|---|
| Fact Book Sales | Sale Price (Sum), Shipping Cost (Sum), Quantity (Sum), Line Total (Sum), Count |
| Fact Order History | Days To Status (Avg), Count |

### Calculated MDX Members

```mdx
[Total Revenue]       = [Measures].[Sale Price]
[Total Orders]        = [Measures].[Fact Book Sales Count]
[Total Shipping Cost] = [Measures].[Shipping Cost]
[Avg Order Value]     = IIF([Measures].[Total Orders]=0, NULL,
                          [Measures].[Total Revenue]/[Measures].[Total Orders])
[Revenue Growth %]    = IIF(PARALLELPERIOD(...)=0, NULL,
                          ([Total Revenue] - LY Revenue) / LY Revenue)
```

---

## 📊 Power BI Dashboards

Connected **live** to the SSAS cube (`localhost\SSAS_MD`). The report has 4 pages:

| Page | Key Visuals |
|---|---|
| Sales Overview | Revenue KPIs, monthly sales trend, top 5 books, sales by shipping method, top 5 countries |
| Customer Analysis | Top 10 customers, revenue by country, revenue by language, order volume by year |
| Order Status | Order funnel, avg days by shipping method, orders by status |
| Book Performance | Top 10 books, top 5 authors, revenue by language, top publishers |

### Real Data Numbers

| Metric | Value |
|---|---|
| Total Revenue | $154,326.69 |
| Total Orders | 15,400 |
| Avg Order Value | $10.02 |
| Total Shipping Cost | **$172,252.40** ⚠️ |
| Top Country | China ($28,013) |
| Top Book | The Brothers Karamazov ($193.18) |
| Top Author | Stephen King (64 books) |
| Top Publisher | Vintage ($4,705) |
| Top Language | English ($124,301 — 80% of revenue) |

---

## 🔍 Key Findings

> **⚠️ Shipping Cost Exceeds Revenue**
>
> Total shipping cost ($172,252) exceeds total revenue ($154,327) by **$17,925** — meaning the bookstore is losing money on every shipment on average. This is the most critical business insight from the analysis and suggests an urgent need to revise the shipping pricing model or renegotiate carrier contracts.

Other findings:
- **80% of revenue** comes from English-language books, with Spanish and French a distant second and third
- **China, Indonesia, and Russia** are the top 3 markets by revenue, together accounting for ~37% of total sales
- Only **46.4%** of orders reach "Delivered" status — the rest remain in earlier stages or are cancelled/returned
- **Priority shipping** averages just 1.1 days to status vs **12.4 days** for International

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

**Why is `time_SK` nullable in Fact Tables?**
The source system only stores order dates — no time component. Storing `00:00:00` would be misleading, so `time_SK` is nullable rather than forced to a fake default.

**Why `publication_year` and `full_name` are computed columns?**
Both are derived from other columns in the same table. Using computed columns ensures they are always consistent with the source data and eliminates the risk of a mismatch during ETL loads — they are never mapped in SSIS.

---

## 👤 Author

**Ahmed Bassiouny**  
Data Engineer

[![GitHub](https://img.shields.io/badge/GitHub-7absy-black?logo=github)](https://github.com/ahmedbassiouny7)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?logo=linkedin)](https://www.linkedin.com/in/ahmed-bassiouny-8966a3184/)

---

> ⭐ If you found this project useful, consider giving it a star!
