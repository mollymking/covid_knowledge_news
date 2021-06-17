local dataset `"01_PewJune2020"'
local category `"06_desc"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:     	Descriptive Statistics - June Knowledge Questions
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

capture net install desctable, from("https://tdmize.github.io/data/desctable")

use  $deriv/ckn05_news`dataset'.dta, clear
save $deriv/ckn`category'`dataset'.dta, replace // data that results at end

***-----------------------------***
// # ANALYTICAL DATASET
***-----------------------------***

drop if fauci_c == .
drop if stateresponse_c == .
drop if antibody_c == .

drop if dG_cnews == .


drop if dG_race == .
drop if dG_age == .
drop if dG_edu3 == .
*drop if dG_pol == .
drop if dB_fem == .
drop if dG_relig == .
drop if dG_finc == . 
drop if dG_newsfol == .

save $deriv/ckn`category'`dataset'.dta, replace // data that results at end

***-----------------------------***
// # DESCRIPTIVES
***-----------------------------***

local demographics "dB_rwhite dB_rblack dB_rasian dB_rhisp dB_rother dB_age_18_29 dB_age_30_49 dB_age_50_64 dB_age_65p dB_inc_l30k dB_inc_30_50k dB_inc_50_75k dB_inc_75_100k dB_inc_100_150k dB_inc_150kp dB_fem dB_edu_HSl dB_edu_sCol dB_edu_colp dB_cnews_natl dB_cnews_local dB_cnews_politicians dB_cnews_pubhealth dB_cnews_informal dB_newsfol_vc dB_newsfol_fc dB_newsfol_n dB_rel_conP  dB_rel_libP  dB_rel_cath  dB_rel_oth  dB_rel_none"


local income_var "dG_finc" 	
local edu_var "dG_edu3"
local dem_categories  "dG_cnews  dG_newsfol dG_age dB_fem  dG_race `income_var'  `edu_var' dG_rel"

* age, gender, race and ethnicity, family income, education, and religion. 
* full sample
	desctable i.dG_cnews i.dG_newsfol ///
		i.dG_race i.dG_age  i.`income_var' dB_fem  i.`edu_var' i.dG_rel, ///
		stats(svymean) ///
		filename($results/ckn`category'`dataset') ///
		sheetname(all)


// Going to use the command postfile to create a record for each variable 
// and its corresponding mean value of correct for each question					
//percentage of people within each demographic who got question correct:
cd $temp/

foreach covid_v in   stateresponse_c  antibody_c fauci_c  { // 

	foreach dem_var of local demographics {
		use $deriv/ckn`category'`dataset'.dta, clear
		
		di in red "Current variable being described is `dem_var'"
	
		tempname `dem_var'_memhold
		tempfile `dem_var'_results
	
		postfile ``dem_var'_memhold' str16 var_name `covid_v'_mean `covid_v'_sd ///
			using ``dem_var'_results'

		quietly svy: mean `covid_v' if  `dem_var' == 1
		estat sd
		
		cap loc mean_var = r(mean)[1,1]
		cap loc sd_var = r(sd)[1,1]
		
		post ``dem_var'_memhold' ("`dem_var'") (`mean_var') (`sd_var')
		
		postclose ``dem_var'_memhold'
		
		clear matrix
		
	} // end of demographics loop
	

*save blank dataset
	clear all
	generate str16 var_name = ""
	save $temp/ckn`category'`dataset'_`covid_v'.dta, replace


// APPEND & MERGE

di in red "Now we are appending tables together for all demographic variables within `covid_v'"

	*tempname `covid_v'_append_memhold
	*tempfile `covid_v'_append_results
	
	*postfile ``covid_v'_append_memhold' str16 var_name `covid_v'mean `covid_v'sd ///
	*	using ``covid_v'_append_results'

	foreach dem_var of local demographics {
		
		*use ``covid_v'_append_results', clear
		use $temp/ckn`category'`dataset'_`covid_v', clear
		append using ``dem_var'_results',
		*save ``covid_v'_append_results', replace
		save $temp/ckn`category'`dataset'_`covid_v'.dta, replace
			
	} // end of demographics loop	

} // end of covid knowledge variable loop
	

	
di in red "Now we are merging tables together across all knowledge variables"
	
*use `fauci_c_append_results', clear
use $temp/ckn06_desc01_PewJune2020_fauci_c.dta, clear
*merge 1:1 var_name using `stateresponse_c_append_results'
merge 1:1 var_name using $temp/ckn06_desc01_PewJune2020_stateresponse_c.dta


tab _merge
drop _merge

*merge 1:1 var_name using `antibody_c_append_results'
merge 1:1 var_name using $temp/ckn`category'`dataset'_antibody_c.dta
	
save $results/ckn`category'`dataset'.dta, replace
	
	

***--------------------------***

log close ckn`category'`dataset'
exit
