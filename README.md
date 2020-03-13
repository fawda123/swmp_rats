---
title: 'Data processing for SWMPrats.net'
author: "Marcus W. Beck, mbeck@tbep.org"
output:
  html_document:
    keep_md: yes
    self_contained: no
  pdf_document:
    toc: yes
---

This project contains scripts for processing SWMP data that are used in the widgets on [swmprats.net](http://swmprats.net/). The widgets include `swmp_summary`, `swmp_comp`, and `swmp_agg`.  `swmp_summary` uses one data object per site and the other two widgets use a summarized data object for all sites.  Follow these steps to update the data on each app. 

* Download most recent data for each site from [http://cdmo.baruch.sc.edu/](http://cdmo.baruch.sc.edu/), zip downloads.
* Put all raw csv files for all station/year combos in `ignore\raw`. Make sure to remove `samplingstations.csv` and `tjrhpnut2002.csv` (only two records).  The downloaded data will include doc and txt files, make sure these are not put in `ignore/raw`. 
* Run `R\dat_proc.R`, this puts processed data in the `ignore\proc1` and `ignore\proc2` folders, one file per site with all data combined.  Data are processed using functions in SWMPr, specifically retaining records with values of 0, 4, and 5 for QAQC flags.  Data in `ignore\proc1` are at 15 minute steps and data in `ignore\proc2` are daily aggregations.
* Upload all files in `ignore\proc2` (daily) to the Amazon S3 server at [https://aws.amazon.com/s3/](https://aws.amazon.com/s3/].) (required login id).  The upload bucket is `swmpagg` on Amazon S3 and permissions must be set to allow downloading by editing the bucket policy.
* Run `R\dat_proc.R` in the `swmp_comp` and `swmp_agg` projects to download and process the updated data from Amazon S3.  This creates files named `data/all_dat.RData` that include the combined data of all sites from the separate daily aggregations data on the server.  Make sure to change the download date in the app descriptions before redeploying.
* Redeploy each shiny app for all three projects.  Make sure to use `deployApp(account='beckmw')`, if account is not found use `setAccountInfo("user", "token", "secret")` with info available from the user account.

