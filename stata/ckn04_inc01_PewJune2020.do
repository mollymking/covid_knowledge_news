local dataset `"01_PewJune2020"'
local category `"04_inc"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***--------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:     	Income variables
//  data:     	di "`dataset'"

//  github:   	covid_knowledge_news
//  OSF:		https://osf.io/qf624/

//  author:   	Molly King

display "$S_DATE  $S_TIME"

***-----------------------------***
// # PROGRAM SETUP
***-----------------------------***

version 16 // keeps program consistent for future replications
set linesize 80
clear all
set more off

use $deriv/ckn03_know`dataset'.dta, clear
save $deriv/ckn`category'`dataset'.dta, replace // data that results at end

***-----------------------------***
// # COMBINE INCOME CATEGORIES FOR ONE BIG CATEGORY VARIABLE
***-----------------------------***

// USE OLD INCOME VARIABLE LABEL TO CREATE NEW VARIABLE LABEL
*label list
codebook f_income
*income uses value label X
uselabel labels82, clear // takes label and converts it into data table
// then can copy this and use it for creating new more robust data label for new variables

use $deriv/ckn`category'`dataset'.dta, clear

label define inc_categories_`dataset' ///
	1	"Less than 10,000" ///
	2	"10,000 to less than 20,000" ///
	3	"20,000 to less than 30,000" ///
	4	"30,000 to less than 40,000" ///
	5	"40,000 to less than 50,000" ///
	6	"50,000 to less than 75,000" ///
	7	"75,000 to less than 100,000" ///
	8	"100,000 to less than 150,000" ///
	9	"150,000 or more" ///
	99	"Refused" 


***-----------------------------***
// CREATE FAMILY INCOME VARIABLE

local family_income_variable f_income

tab `family_income_variable', m
tab `family_income_variable', m nolab

clonevar dL_finc = `family_income_variable'

*check if coded correctly
tab dL_finc `family_income_variable', m
tab dL_finc `family_income_variable', m

recode dL_finc 99 = .n //	Don't Know/refused

label var dL_finc "family Income"
lab val dL_finc inc_categories_`dataset'
notes dL_finc:`dataset' Family Income Categories from `family_income_variable' \ ckn`category'`dataset'.do mmk $S_DATE


***-----------------------------***
// CREATE FAMILY INCOME VARIABLE - LARGER CATEGORIES

tab dL_finc f_income_recode, m

label define inc_categories_broader ///
	1	"Less than 30,000" ///
	2	"30,000 to to less than 50,000" ///
	3	"50,000 to less than 75,000" ///
	4	"75,000 to less than 100,000" ///
	5	"100,000 to less than 150,000" ///
	6	"150,000 or more" ///
	.n	"Refused" 

gen		dG_finc = .
replace dG_finc = 1 if dL_finc == 1 | dL_finc == 2 | dL_finc == 3
replace dG_finc = 2 if dL_finc == 4 | dL_finc == 5
replace dG_finc = 3 if dL_finc == 6
replace dG_finc = 4 if dL_finc == 7
replace dG_finc = 5 if dL_finc == 8
replace dG_finc = 6 if dL_finc == 9
replace dG_finc = . if dL_finc == .n


label var dG_finc "family Income - categories more than 1000 respondents"
lab val dG_finc inc_categories_broader
notes dG_finc:`dataset' Family Income Categories from `family_income_variable' \ ckn`category'`dataset'.do mmk $S_DATE

tab f_income dG_finc, m

// Binary Income Categories

local inc_var dG_finc
tab `inc_var', m nolab

*refused code(s) for `inc_var'
local inc_missing_condition `"`inc_var' == .n"' //Refused

local incl30k_condition 	`"`inc_var' == 1"' //	
local inc30_50k_condition 	`"`inc_var' == 2"' //	
local inc50_75k_condition 	`"`inc_var' == 3"'	// 
local inc75_100k_condition 	`"`inc_var' == 4"'	// 
local inc100_150k_condition `"`inc_var' == 5"'	// 
local inc150kp_condition 	`"`inc_var' == 6"'	// 

local inclist "l30k 30_50k 50_75k 75_100k 100_150k 150kp"
foreach inc of local inclist {
	gen dB_inc_`inc' = 0
	// Replace each with . for missing 
		if "`inc_missing_condition'" != "none" {
			replace dB_inc_`inc' = . if `inc_missing_condition'
		}
	label var dB_inc_`inc' "Inc category `inc'"
	label define dB_inc_`inc' 0 "Not `inc'" 1 "`inc'"
		label val dB_inc_`inc' dB_inc_`inc'
	notes dB_inc_`inc': Income category `inc'. created from `inc_var' variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE

	replace dB_inc_`inc' = 1 if `inc`inc'_condition'
}

tab `inc_var' dG_finc, m
tab `inc_var' dB_inc_l30k, m
tab `inc_var' dB_inc_75_100k, m


// SAVE
save $deriv/ckn`category'`dataset'.dta, replace 

***-----------------------------***
log close ckn`category'`dataset'
exit
