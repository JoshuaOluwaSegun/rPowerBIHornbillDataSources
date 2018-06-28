### [Power BI](https://powerbi.microsoft.com/) [R Script](https://cran.r-project.org/) Data Sources for Hornbill Reporting And Trend Engine

## Overview
These example scripts have been provided to enable Power BI administrators to build reports and dashboards using Hornbill Reporting and Advanced Analytics Trend Engine data as their data source(s).

## Dependencies

The scripts have been written in [R](https://cran.r-project.org/), and were developed using the following:

 - [Power BI Desktop build 2.45.4704.722 64-bit (April 2017)](https://powerbi.microsoft.com/)
 - [Microsoft R Open 3.3.3](https://mran.microsoft.com/open/)

The following packages are required dependencies, and can be installed via the CRAN repositories:

 - [RCurl](https://cran.r-project.org/web/packages/RCurl/)
 - [XML](https://cran.r-project.org/web/packages/XML/)
 - [jsonlite](https://cran.r-project.org/web/packages/jsonlite/)

## Configuration used in all scripts

Each script requires the following variables to be set (all case-sensitive):
 - instanceName - This is the name of the instance to connect to
 - instanceZone - This is the zone where the instance resides
 - apiKey - This is an API key generated against a user account on the Hornbill Administration Console, where the user account has sufficient access to run reports and access trending data.

## Scripts
##### PowerBIDataSource_Report.R
This script will:
 - Run a pre-defined report on the Hornbill instance;
 - Wait for the report to complete;
 - Retrieve the report CSV data and present back as an R data frame called output, which can then be retrieved and reported on by PowerBI.

Script Variables:
 - reportID: The ID (Primary Key, INT) of the  report to be run;
 - reportComment: A comment to write against the report run job.
 - deleteReportInstance: a boolean value to determine if, once the report is run on Hornbill and the data has been pulled in to PowerBI, whether the historic report run instance should be removed from your Hornbill report.
 - suspendSeconds: The number of seconds the script should wait between checks to see if the report is complete. NOTE : there is a defect/incompatibility between Power BI and the RCurl library that we are using to make the HTTP requests to Hornbill, where if more than 4 or 5 calls with getURL are made within the same script then getURL hangs until Power BI releases it. Increasing the number of seconds between checks reduces the required number of calls to your Hornbill instance, and will fix data source hanging issues.

##### PowerBIDataSource_Report.R
This script will:
 - Retrieve a historic report CSV from your Hornbill instance;
 - Present the report data back as an R data frame called dataframe, which can then be retrieved and reported on by PowerBI.

Script Variables:
 - reportID: The ID (Primary Key, INT) of the  report to be run;
 - runId: The Run ID (INT) of a historic run of the above report ID.

##### PowerBIDataSource_TrendingData.R
This script will:
 - Run the reporting::measureGetInfo API  against your Hornbill instance, with a given measure ID (Primary Key, INT);
 - Build a table containing all Trend Value entries for the selected measure;
 - Present the trend data back as an R data frame called dataframe, which can then be retrieved and reported on by PowerBI.

Script Variable:
 - measureID: The ID (Primary Key, INT) of the measure to return trend data from.

Outputs:
As the response parameters from the Trending Engine is fixed (unlike the Reporting engine, which has user-specified column outputs), the output for this report will always consist  of the following columns:

 - value - the value of the trend sample;
 - sampleId - the ID of the sample;
 - sampleTime - the time & date that the sample was taken;
 - dateRange.from - the start date of the sample snapshot;
 - dateRange.to - the end date of the sample snapshot;

## Power BI Notes

These scripts have been designed to be used as data sources only, and not as the source of R script visuals within Power BI. Which is not to say they couldn't be used in your R script visuals, with a little extra code :)