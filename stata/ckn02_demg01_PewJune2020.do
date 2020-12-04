local dataset `"01_PewJune2020"'
local category `"02_demg"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:     	Create Demographic Variables
/*  data:    */ di "`dataset'"

//  github:   	covid_knowledge_news
//  OSF:		https://osf.io/qf624/

//  author:   	Molly King

display "$S_DATE  $S_TIME"

***--------------------------***
// # PROGRAM SETUP
***-----------------------------***

version 16 // keeps program consistent for future replications
set linesize 80
clear all
set more off

use $deriv/ckn01_impe01_PewJune2020.dta, clear

*Details on demographic variables from:
* https://www.pewresearch.org/wp-content/uploads/2018/05/Codebook-and-instructions-for-working-with-ATP-data.pdf

***-----------------------------***
// # YEAR
***-----------------------------***

*All interviews carried out in June 2020
/*
	"Last year, that is in [FILL LAST YEAR], 
	what was your total family income from all sources,
	before taxes?  (READ)"
*/

gen year = 2019
local year "year"
label var year "Year for income was 2019"

gen survey_year = 2020

***-----------------------------***
// # GENDER
***-----------------------------***

local gender_var f_sex

tab `gender_var', m
tab `gender_var', nolab m

include $stata/ckn02_demg00_include_female_from2W_1M.doi 


***--------------------------***
// # RACE / ETHNICITY
***-----------------------------***

local race_var f_racecmb
tab `race_var'
tab `race_var', m nolab

local hisp_var f_hisp
if "`hisp_var'" != "none" {
	tab `hisp_var', m
	tab `hisp_var', m nolab
	tab `race_var' `hisp_var'
}

*don't know/refused code(s) for `race_var'
local race_missing_condition `"`race_var' == 9"'

local white_race_value = 	1
local black_race_value = 	2
local asian_race_value = 	3
local other_race_value =	5
local mult_race_value =  	4
local amerInd_race_value  	none
local hisp_value = 			1

include $stata/ckn02_demg00_racethnicity.doi


* Create white/nonwhite variables
gen dB_bipoc = .

replace dB_bipoc = 1 if `race_var' == `black_race_value'
replace dB_bipoc = 1 if `race_var' == `asian_race_value' 
replace dB_bipoc = 1 if `race_var' == `other_race_value'
replace dB_bipoc = 1 if `race_var' == `mult_race_value'
replace dB_bipoc = 1 if `race_var' == `hisp_value'

replace dB_bipoc = 0 if `race_var' == `white_race_value'

replace dB_bipoc = . if `race_missing_condition'

label var dB_bipoc "BIPOC Binary race variable"
label define dB_bipoc 1 "1_BIPOC" 0 "0_White"
	label val  dB_bipoc  dB_bipoc

	
***--------------------------***
// # EDUCATION
***-----------------------------***

local edu_var f_educcat2
tab `edu_var'
tab `edu_var', nolab m

*don't know/refused code(s) for `edu_var'
local edu_missing_condition `"`edu_var' == 99"'

* Conditions for each category
local lHS_condition 	`"`edu_var' == 1"'
local HS_condition 		`"`edu_var' == 2"'
local sCol_condition	`"`edu_var' == 3 | `edu_var' == 4"'
local col_condition		`"`edu_var' == 5"'
local grad_condition	`"`edu_var' == 6"'

include $stata/ckn02_demg00_education.doi


***-----------------------------***
// # AGE
***-----------------------------***

local age_var f_agecat

*codebook `age_var'
*uselabel labels66, clear

tab `age_var', m
tab `age_var', m nolab

*don't know/refused code(s) for `age_var'
local age_missing_condition `"`age_var' == 99"' //Refused

local age18_29_condition `"`age_var' == 1"' //	18-29
local age30_49_condition `"`age_var' == 2"' //	30-49
local age50_64_condition `"`age_var' == 3"'	// 50-64
local age65p_condition 	 `"`age_var' == 4"'	// 65+


// Categorical Age
gen dG_age = .
	label var dG_age "Categorical age variable"
	label define age_4categ 1	"18-29" 2	"30-49" 3	"50-64" 4	"65plus"
		label val dG_age age_4categ
	notes dG_age: Age categorical variable, created from `age_var' variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE

	replace dG_age 	   = 1 if `age18_29_condition'
	replace dG_age 	   = 2 if `age30_49_condition'
	replace dG_age 	   = 3 if `age50_64_condition'
	replace dG_age 	   = 4 if `age65p_condition'
	
local agelist "18_29 30_49 50_64 65p"
foreach age of local agelist {
	gen dB_age_`age' = 0
	// Replace each with . for missing 
		if "`age_missing_condition'" != "none" {
			replace dB_age_`age' = . if `edu_missing_condition'
		}
	label var dB_age_`age' "Age category `age'"
	label define dB_age_`age' 0 "Not `age'" 1 "`age'"
		label val dB_age_`age' dB_age_`age'
	notes dB_age_`age': Age category `age'. created from `age_var' variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE

	replace dB_age_`age' = 1 if `age`age'_condition'
}

*tab `age_var' dG_age, m
*tab `age_var' dB_age_18_29, m
*tab `age_var' dB_age_65p, m


***-----------------------------***
// SAVE DATA	
***-----------------------------***

label data "`dataset' Demographics"
notes: ckn`category'`dataset'.dta \ `dataset' with recoded dempgraphics \ ckn`category'`dataset'.do mmk $$_DATE
compress
datasignature set, reset
save $deriv/ckn`category'`dataset'.dta, replace


***--------------------------***

log close ckn`category'`dataset'
exit
