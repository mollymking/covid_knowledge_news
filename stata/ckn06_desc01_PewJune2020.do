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

use  $deriv/ckn05_news`dataset'.dta, clear
save $deriv/ki`category'`dataset'.dta, replace // data that results at end



***-----------------------------***
// # DESCRIPTIVES
***-----------------------------***
local demographics "dB_rwhite dB_rblack dB_rasian dB_rhisp dB_rother dB_age_18_29 dB_age_30_49 dB_age_50_64 dB_age_65p dB_inc_l30k dB_inc_30_50k dB_inc_50_75k dB_inc_75_100k dB_inc_100_150k dB_inc_150kp dB_fem dB_edu_lHS dB_edu_HS dB_edu_sCol dB_edu_col dB_edu_grad dB_crely_international dB_crely_national dB_crely_local dB_crely_trump dB_crely_biden dB_crely_politicians dB_crely_ph dB_crely_friends dB_crely_neighbor dB_crely_online dB_newsfol_vc dB_newsfol_fc dB_newsfol_n"

*percentage of people within each demographic who got question correct:

foreach dem_var of local demographics {
	
	di in red "Mean correct for `dem_var'"
	svy: mean fauci_c stateresponse_c antibody_c if `dem_var' == 1
	
}

*Overall percentages correct:
svy: mean fauci_c  
svy: mean stateresponse_c
svy: mean antibody_c

/*
foreach v in fauci   stateresponse  antibody { // 

*percentage of people who got question correct who are each demographic:
*split by whether got question correct or not, then look at proportion of each demographic variable in each category. This would result in 6 (or 8) columns of demographics
* use svy: mean dB_rwhite if antibody_c ==1

	*https://stats.idre.ucla.edu/stata/seminars/applied-svy-stata13/
	
	di in red "Mean correct for `v'"
	svy: mean `demographics' if `v'_c == 1
	
	di in red "Mean incorrect for `v'"
	svy: mean `demographics' if `v'_c == 0
	
}


***--------------------------***

log close ckn`category'`dataset'
exit
