<div align="center">

# 📊 Data Warehouse & Analytics Project

### From scattered CSV files to clear business answers, using SQL Server

![SQL Server](https://img.shields.io/badge/Database-SQL%20Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![SQL](https://img.shields.io/badge/Language-SQL-336791?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-In%20Progress-F5A623?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-2EA44F?style=for-the-badge)

</div>

---

## 📖 About This Project

Most companies keep their data in many different places. Sales data sits in one system, customer data sits in another, and the two rarely match.

This project solves that problem step by step. I take raw data from two source systems, clean it, join it into one simple data model, and then use SQL to answer real business questions.

It is a hands-on portfolio project that shows the full journey of a data professional: **building the warehouse first, then using it to find insights.**

---

## 🎯 Project Goals

The project has two main parts.

| Part | Role | Goal |
|------|------|------|
| 🏗️ **Part 1** | Data Engineering | Build a modern data warehouse in SQL Server that brings all sales data together in one place. |
| 📈 **Part 2** | Data Analytics | Write SQL queries on top of the warehouse to understand customers, products, and sales. |

---

## 🔄 How the Data Flows

# Data Warehouse and Analytics Project

![DATABASE](https://img.shields.io/badge/DATABASE-SQL%20SERVER-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![STATUS](https://img.shields.io/badge/STATUS-IN%20PROGRESS-F5A623?style=for-the-badge)
![LICENSE](https://img.shields.io/badge/LICENSE-MIT-2EA44F?style=for-the-badge)

A hands-on SQL project. It takes raw sales data from two systems, cleans it, joins it into one simple data model, and then uses that model to answer real business questions.

⭐ If this project helps you, give the repository a star so other learners can find it too.

New here? Open the `Docs` folder first. It explains the data model in plain words. The `Scripts` folder holds the SQL files, in the order you should run them.

```text
data-warehouse-and-analytics-project/
├── Database/     database setup and data model files
├── Docs/         notes and documentation of the data model
├── Scripts/      SQL scripts: import, clean, combine, analyze
├── Tests/        checks to confirm the data is correct
├── LICENSE       the MIT license
└── README.md     this file
```

The data moves through the project like this:

```text
ERP (CSV) ─┐
           ├─> Import ─> Clean ─> Combine ─> Analyze ─> Insights
CRM (CSV) ─┘
```

## 🚀 Project Requirements

### 🏗️ Part 1: Build the Data Warehouse (Data Engineering)

**Goal:** Build a modern data warehouse in SQL Server that keeps all sales data in one place, so reports are easy to make and decisions are easier to take.

- **Sources:** Load data from two systems, ERP and CRM. Both come as CSV files.
- **Quality:** Find and fix problems in the raw data before any analysis starts.
- **Integration:** Join both sources into one clean data model that is easy to query.
- **Scope:** Use the latest data only. Keeping a full history of changes is not needed.
- **Documentation:** Explain the data model clearly, so business users and analysts can both understand it.

### 📈 Part 2: Analytics and Reporting (Data Analytics)

**Goal:** Write SQL queries on top of the warehouse to get clear answers about:

- **Customer Behavior**: who our customers are and how they buy
- **Product Performance**: which products do well and which need attention
- **Sales Trends**: how sales change over time

These answers give stakeholders the key numbers they need to make confident decisions.

## 🧰 Tools

`SQL Server` · `SQL` · `CSV files` · `Git` · `GitHub`

## 🤝 Connect

💼 *LinkedIn:* https://www.linkedin.com/in/shanto85206
📧 *Email:* santinoshan56@gmail.com
## 🛡️ License

[MIT](LICENSE). Use it, change it, share it, with credit.

This project was inspired by the free SQL lessons from [Data With Baraa](https://github.com/DataWithBaraa/sql-ultimate-course).

## 🌟 About me

Hi, I'm **Shanto Islam**, a junior data analyst from Bangladesh. After years of data entry and spreadsheet work, I know that one small error can cause big problems later, so I check my work carefully. With this project I practice turning messy data into clear, decision-ready insights using SQL.

---

## 🏗️ Part 1: Building the Data Warehouse

**Objective:** Create a modern data warehouse in SQL Server that collects sales data in one place, so reports are easy to build and decisions are easier to make.

| Area | What I Will Do |
|------|----------------|
| 📥 **Data Sources** | Load data from two systems, **ERP** and **CRM**, which arrive as CSV files. |
| 🧹 **Data Quality** | Find and fix problems in the raw data (duplicates, wrong formats, missing values) before any analysis starts. |
| 🔗 **Integration** | Merge both sources into one clean, easy-to-understand data model made for analytical queries. |
| 🎯 **Scope** | Work with the latest data only. Keeping a full history of changes is not needed here. |
| 📝 **Documentation** | Write clear notes about the data model so both business users and analysts can understand it. |

---

## 📈 Part 2: Analytics & Reporting

**Objective:** Use SQL to turn the warehouse data into useful answers for the business.

| Focus Area | What It Helps Us Understand |
|------------|-----------------------------|
| 👥 **Customer Behavior** | Who our customers are and how they buy. |
| 📦 **Product Performance** | Which products do well and which ones need attention. |
| 📊 **Sales Trends** | How sales change over time. |

The final results give stakeholders the key numbers they need to make confident, strategic decisions.

---

## 📁 Repository Structure

```text
📦 Data-Warehouse-and-Analytics-Project
 ┣ 📂 Database    → Database setup and data model files
 ┣ 📂 Docs        → Project notes and data model documentation
 ┣ 📂 Scripts     → SQL scripts (import, cleaning, transformation, analysis)
 ┣ 📂 Tests       → Checks to confirm the data is correct
 ┣ 📄 LICENSE     → MIT License
 ┗ 📄 README.md   → You are here
```

---

## 🛠️ Tools Used

| Tool | Purpose |
|------|---------|
| **SQL Server** | Storing data and building the warehouse |
| **SQL** | Cleaning, transforming, and analyzing data |
| **CSV Files** | Source data from ERP and CRM |
| **Git & GitHub** | Version control and sharing the project |

---

## 🗺️ Project Roadmap

- [x] Create the repository and folder structure
- [ ] Understand the ERP and CRM source data
- [ ] Import the CSV files into SQL Server
- [ ] Clean the data and fix quality issues
- [ ] Combine both sources into one data model
- [ ] Write documentation for the data model
- [ ] Run SQL analysis on customers, products, and sales
- [ ] Add tests and final project summary

---

## 🚀 Getting Started

1. **Clone** this repository to your computer.
2. **Install** SQL Server and a tool to run SQL queries.
3. **Place** the ERP and CRM CSV files in the project.
4. **Run** the scripts from the `Scripts` folder in order.
5. **Read** the `Docs` folder to understand the data model.

> 💡 This project is still growing, so steps and files will be updated as I make progress.

---

## 📄 License

This project is licensed under the **MIT License**. You are free to use, change, and share it, as long as you give proper credit.

---

## 👤 About Me

Hi, I'm **Shanto Islam**, a Junior Data Analyst from Dhaka, Bangladesh. 👋

I turn messy data into clear, decision-ready insights using **SQL, Excel, and Data Cleaning**. I believe one small error in data can cause big problems later, so I always check my work carefully.

📧 **Email:** santinoshan56@gmail.com
💼 **LinkedIn:** https://www.linkedin.com/in/shanto85206

<div align="center">

⭐ If you find this project useful, please give it a star! ⭐

</div>
