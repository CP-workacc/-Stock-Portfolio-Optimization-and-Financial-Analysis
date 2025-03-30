# Portfolio Optimization and Financial Data Analysis

This project involves designing a portfolio optimization and financial data analysis system using the Mean-Variance framework. It includes a single SQL script and R code for data extraction, transformation, and analysis. The objective is to optimize a portfolio by analyzing financial data, implementing statistical models, and visualizing the results.

## Files
- Documentation/: Contains the project report, methodology, and data dictionary.
  - Project_Report.pdf: The detailed project report that outlines the problem, methodology, results, and conclusions.
  - Methodology.docx: The document describing the approach and algorithms used in the project.
  - Data_Dictionary.csv: A dictionary of the data used in the project, including variable descriptions and data types.

- SQL_Files/: Contains the SQL script used for data extraction, transformation, and processing.
  - project.sql: The main SQL script for loading, processing, and querying financial data.

- R_Files/: Contains the R code for data analysis and portfolio optimization.
  - project_script.R: R code used to analyze the financial data, implement the mean-variance optimization, and visualize the results.

- Data/: Contains the data files used in the project.
  - customer_calendar.csv: Data containing customer transaction records and related information.
  - SP500TR.csv: Data containing historical returns for the S&P 500 Total Return index.

## How to Use
1. Clone the Repository:
   - Download or clone the repository to your local machine using Git:
     git clone https://github.com/CP-workacc/-Stock-Portfolio-Optimization-and-Financial-Analysis/tree/master
   
2. Run SQL Script:
   - Open your SQL client (e.g., pgAdmin, SQL Server Management Studio, or MySQL Workbench).
   - Run the `project.sql` script to create the necessary tables and load financial data.
   
3. Execute the R Script:
   - Open RStudio or any R environment.
   - Install necessary libraries (if not already installed):
     install.packages("quantmod")
     install.packages("tseries")
     install.packages("ggplot2")
   - Run the `project_script.R` to analyze the data, optimize the portfolio, and generate visualizations.

## Notes
- Ensure that your SQL database contains the correct financial data for the script to work.
- The R script assumes that data is available in the tables created by the SQL script.
- This project uses real-time NASDAQ data to calculate optimal portfolio allocations using the Mean-Variance framework.
