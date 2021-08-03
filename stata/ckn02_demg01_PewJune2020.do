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

*3-category Education Variable
gen dG_edu3 = .
label var dG_edu3 "Categorical education variable"
label define edu_3categ 1 "HS or less" 2 "some college" 3 "college+"
	label val dG_edu3 edu_3categ
notes dG_edu3: Education 3-categorical variable, created from `edu_var' variable in `dataset' \ ki`category'`dataset'.do mmk $S_DATE

*High school or less
gen dB_edu_HSl = 0
	// Replace each with . for missing edu. if there is a edu. missing condition: 
replace dB_edu_HSl = . if `edu_missing_condition'
label var dB_edu_HSl "HS or less"
label define dB_edu_HSl 0 "0_>HS" 1 "1_HSless"
	label val dB_edu_HSl dB_edu_HSl
notes dB_edu_HSl: HS or less edu. created from `edu_var' variable in `dataset' \ ki`category'`dataset'.do mmk $S_DATE
		
replace dB_edu_HSl = 1 if `edu_var' == 1 | 	`edu_var' == 2
replace dG_edu3    = 1 if `edu_var' == 1 | 	`edu_var' == 2
	
*some college
replace dG_edu3    = 2 if `sCol_condition'

*college plus
*dB_edu_colp
replace dG_edu3	   = 3 if `col_condition' | `grad_condition'
	
	
tab dG_edu dG_edu3, m	

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
			replace dB_age_`age' = . if `age_missing_condition'
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
// # RELIGION	
***-----------------------------***

tab f_relig f_born
tab f_born, m nolabel
tab f_born, m 
tab f_relig, nolabel
tab f_relig

// Conservative Protestant
*following Evans & Hargittai 2020, assign those describing themselves as evangelical to conservative dummy variable

gen dB_rel_conP = 0
replace dB_rel_conP = . if f_relig == 99 // refused
replace dB_rel_conP = 1 if f_born == 1 & f_relig == 1 // protestant and "evangelical / born again"

label define relig_conP ///
	0	"Other"  ///
	1	"Conservative Protestant"
label val dB_rel_conP relig_conP

notes dB_rel_conP: Conservative Protestant, created from f_born variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE
	
	
// Liberal Christian

gen dB_rel_libP = 0
replace  dB_rel_libP = . if f_relig == 99 // refused
replace  dB_rel_libP = 1 if f_born == 2 & f_relig == 1 // protestant and  NOT "evangelical / born again"
label define relig_libP ///
	0	"Other"  ///
	1	"Liberal Protestant"	
label val  dB_rel_libP relig_libP

notes  dB_rel_libP: Liberal Protestant, created from f_born variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE
	
	
// Catholic

gen dB_rel_cath = 0
replace  dB_rel_cath = . if f_relig == 99 // refused
replace  dB_rel_cath = 1 if f_relig == 2

label define relig_cath ///
	0	"Other"  ///
	1	"Catholic"
label val dB_rel_cath relig_cath

notes  dB_rel_cath: Catholic, created from f_born variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE
	

// Strong no-identity Christian 
*tab f_relig f_attend if f_born !=1 & f_born !=2
// Low participation Christian 


// Other
tab f_relig, m
tab f_relig, m nolab

gen dB_rel_oth = 0
replace  dB_rel_oth = 1 if f_relig == 3  // mormon
replace  dB_rel_oth = 1 if f_relig == 4  // orthodox
replace  dB_rel_oth = 1 if f_relig == 5  // jewish
replace  dB_rel_oth = 1 if f_relig == 6  // muslim
replace  dB_rel_oth = 1 if f_relig == 7  // buddhist
replace  dB_rel_oth = 1 if f_relig == 8  // hindu
replace  dB_rel_oth = 1 if f_relig == 11 // other	
replace  dB_rel_oth = . if f_relig == 99  // refused

label define relig_other ///
	0	"Christian,Catholics, Nones"  ///
	1	"Other Religions"	
label val dB_rel_oth relig_other

notes  dB_rel_oth: Other religions, created from f_born variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE
	

// Nonreligious (Atheist, Agnostic, None)

gen dB_rel_none = 0
replace dB_rel_none = 1 if f_relig == 9 // atheist
replace dB_rel_none = 1 if f_relig == 10 // agnostic
replace dB_rel_none = 1 if f_relig == 12 // nothing in particular
replace  dB_rel_none = . if f_relig == 99 // refused
	
label define relig_none ///
	0	"Other" ///
	1 	"Nonreligious - Atheist / Agnostic / Nothing in particular"
label val dB_rel_none relig_none

notes  dB_rel_none: Nonreligious, created from f_born variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE


// Categorical

gen dG_relig = .
replace  dG_rel = 1 if dB_rel_conP == 1 // Conservative Protestant
replace  dG_rel = 2 if dB_rel_libP == 1 // Liberal Protestant
replace  dG_rel = 3 if dB_rel_cath == 1 // Catholic
replace  dG_rel = 4 if dB_rel_oth == 1 // Other
replace  dG_rel = 5 if dB_rel_none == 1 // Nonreligious
replace  dG_rel = . if f_relig == 99  // refused


label define relig ///
	1	"Conservative Protestant"	///
	2	"Liberal Protestant"		///
	3	"Catholic"					///
	4	"Other"						///
	5	"Nonreligious"	
label val dG_rel relig

notes  dG_rel: Categorical religion, created from f_born variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE

tab  f_relig dG_rel, m




***-----------------------------***
// # PARTY / IDEOLOGY
***-----------------------------***
tab f_partysum_final, m
tab f_partysum_final, m nolab
tab f_party_final

*F_PARTYSUM_FINAL
*Party summary recoded off F_PARTY_FINAL and F_PARTYLN_FINAL.
	// 1 Rep/Rep Lean
	// 2 Dem/Dem Lean
	// 3 Independent/No Lean
	// 99 DK/Ref
	
// Political Party
label define pol_party ///
	0	"Republican"  ///
	1	"Democrat" ///
	2	"Independent"

gen dG_pol = .
	replace dG_pol = 0 if f_party_final == 1 	// Republican
	replace dG_pol = 1 if f_party_final == 2	// Democrat
	replace dG_pol = 2 if f_party_final == 3	// Independent
label var  dG_pol "Political Party"

label val dG_pol pol_party
notes  dG_pol: Political party, created from f_party_final variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE
	
tab f_party_final dG_pol, m

// Democratic Party - dB_dem - use with dB_ind
label define dem_party ///
	0	"Other"  ///  omitted "something else"
	1	"Democrat"

gen dB_pol_dem  = .
	replace  dB_pol_dem  = 0 if f_party_final == 1 	// Repubs
	replace  dB_pol_dem = 1 if f_party_final == 2 	// Dems
	replace  dB_pol_dem = 0 if f_party_final == 3	// Ind
label var dB_pol_dem  "Democratic Party"

label val dB_pol_dem dem_party
notes dB_pol_dem : Binary Democratic, created from f_party_final variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE

tab dB_pol_dem f_party_final, m

// Independent - dB_ind - use with dB_dem
label define ind_party ///
	0	"Other"  /// omitted "something else"
	1	"Independent"

gen dB_pol_ind = .
	replace   dB_pol_ind = 0 if f_party_final == 1 	// Rep
	replace   dB_pol_ind = 1 if f_party_final == 3	// Ind
	replace   dB_pol_ind = 0 if f_party_final == 2 	// Dem
label var  dB_pol_ind "Independent"

label val  dB_pol_ind ind_party
notes  dB_pol_ind: Binary Independent, created from f_party_final variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE
	
tab dB_pol_ind f_party_final, m

	
// Democratic Party / lean - Binary
label define partylean ///
	0	"Republican / Rep lean"  ///
	1	"Democrat / Dem lean"

gen dB_demlean = .
	replace  dB_demlean = 0 if f_partysum_final == 1 	
	replace  dB_demlean = 1 if f_partysum_final == 2
label var dB_demlean "Democratic Party / lean"

label val dB_demlean partylean
notes dB_demlean: Binary Democratic / Dem lean, created from f_partysum_final variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE


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
