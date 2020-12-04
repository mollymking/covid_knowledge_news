local dataset `"01_asec"'
local category `"01_impe"'
cd $impe // import directory

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:     	Create Demographic Variables
//  data:    	CPS ASEC from IPUMS, available: https://cps.ipums.org/

//  github:   	covid_knowledge_news
//  OSF:		https://osf.io/qf624/

//  author:   	Molly King


display "$S_DATE  $S_TIME"

***--------------------------***
// PROGRAM SETUP
***--------------------------***

version 16 // keeps program consistent for future replications
set linesize 80
clear all
set more off

***--------------------------***
// EXTRACT DATA
***--------------------------***

// Code to extract is from IPUMS CPS ASEC do file for importing data - 
// just have to change working directory to redirect to where store original data
// and change name of .do file to match below

cd $source/
// this is code provided by IPUMS - ACS to import data:
do $stata/cps_00011.do // larger data set includes variables for later regression


// CLEAN UP A BIT
keep if year == 2019


***--------------------------***
// FAMILY INCOME
***--------------------------***

// SURVEY WEIGHT INFO
// svyset [iweight=hwtsupp] 
	// household weight for 

keep if pernum == 1
svyset [pweight=asecwth]

*svy: mean hhincome

***--------------------------***
// # SAVE DATA
***--------------------------***

label data "Imported original CPS ASEC data from IPUMS"
notes: ckn01_impe03_asec.dta \ Extracted CPS ASEC Data from IPUMS \ ckn01_03_asec-extr.do mmk $DATE
compress
datasignature set, reset
save $deriv/ckn01_impe03_asec.dta, replace


***--------------------------***

log close ckn`category'`dataset'
exit
