local dataset `"01_PewJune2020"'
local category `"07_regr"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:		Regression Models - June Knowledge Questions
/*  data:    */ di "`dataset'"

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

*use $deriv/ckn05_news`dataset'.dta, clear
use $deriv/ckn06_desc`dataset'.dta, clear
save $deriv/ckn`category'`dataset'.dta, replace // data that results at end

cd $deriv

***-----------------------------***
// # CREATE ANALYTICAL DATASET
***-----------------------------***

save $deriv/ckn`category'`dataset'.dta, replace // data that results at end

***-----------------------------***
// # NOTES / COMMANDS
***-----------------------------***

capt ssc install outreg2, replace

*svylogitgof
*https://journals.sagepub.com/doi/10.1177/1536867X0600600106

*use of linktest
*https://stats.idre.ucla.edu/stata/webbooks/logistic/chapter3/lesson-3-logistic-regression-diagnostics/

***-----------------------------***
// # MODELS w CATEGORICAL RACE VARIABLE & ALL NEWS VARIABLEs
***-----------------------------***

// STORE BASE LEVELS for INTERACTIONS

local income_var "i.dG_finc" 	// 
fvset base 1 dG_finc 		// ref: less than $30,000

fvset base 1 dG_cnews 		// ref: dB_cnews_news 

local edu_var "i.dG_edu3"
fvset base 1 dG_edu  		// ref: less than HS

*set base to international/national or public health
*fvset base 1 dG_cnews		// ref: National / International news outlets
fvset base 4 dG_cnews		// ref: public health
fvset base 7.00  dG_crely 		// ref: public health

fvset base 3 dG_newsfol 	// ref: How closely following news? not too / at all closely


rename stateresponse_c stater_c // shorten variable

foreach v in antibody fauci stater   { // 

***-----------------------------***
// # MODEL A for ONLINE APPENDIX: NEWS SOURCE (ORIGINAL EXTENDED VARIABLE)
***-----------------------------***

// # BASIC MODEL A -  EXTENDED NEWS SOURCE

	svy: logit `v'_c  ///	
		i.dG_crely ///
		, or baselevels // report Odds Ratios
	
	est store `v'_ex

	
// # A -  EXTENDED NEWS SOURCE + RACE + INCOME + EDUCATION

	svy: logit `v'_c  ///	
		i.dG_crely ///
		i.dG_race  `income_var' ///
		`edu_var' ///
		, or baselevels // report Odds Ratios
	
	est store `v'_ex_class

	
// # A -  EXTENDED NEWS SOURCE + CONTROLS + EDUCATION + RELIGION

	svy: logit `v'_c  ///	
		i.dG_crely	///
		i.dG_race  `income_var' ///
		`edu_var' ///
		i.dG_newsfol ///
		i.dG_age dB_fem  ///
		i.dG_rel ///
		, or baselevels // report Odds Ratios
	
	est store `v'_ex_class_ctrl



***-----------------------------***
// # FINAL MODEL: NEWS SOURCE + HOW CLOSELY FOLLOW NEWS
***-----------------------------***

// # BASIC MODEL -  NEWS SOURCE ONLY

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: cnews_news
		, or baselevels // report Odds Ratios
	
	est store `v'_cn

// # BASIC MODEL -  NEWS SOURCE + HOW CLOSELY FOLLOW NEWS

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		, or baselevels // report Odds Ratios

		estat gof 
		linktest
	
	est store `v'_cn_nf

	
// # NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + CONTROLS + EDUCATION		

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age  dB_fem i.dG_race  `income_var'  ///
		`edu_var'  ///
		, or baselevels // report Odds Ratios
		
		estat gof 
		linktest
	
	est store `v'_cn_nf_ct_ed

// # NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + CONTROLS + EDUCATION + RELIGION	

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_race  `income_var'   ///
		`edu_var'  ///
		, or baselevels // report Odds Ratios
		
		estat gof 
		linktest
	
	est store `v'_cn_race_ed_inc
	

// #  NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + CONTROLS + EDUCATION + RELIGION	

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age dB_fem i.dG_race  `income_var'   ///
		`edu_var'  ///
		i.dG_rel ///
		, or baselevels // report Odds Ratios
		
		estat gof 
		linktest
	
	est store `v'_cn_nf_ct_ed_rl
	
} // Close loop through variables	
	
***-----------------------------***			
// # MODEL: NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + CONTROLS + EDUCATION + POLITICAL PARTY	+ RELIGION	
***-----------------------------***

drop if dG_pol == . /// drop if missing data on politics variable (not dropped previously in descriptives file)

foreach v in antibody fauci stater   { // 

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_race i.dG_age  `income_var' dB_fem  ///
		`edu_var'  ///
		i.dG_pol ///
		i.dG_rel ///
		, or baselevels // report Odds Ratios
		
		estat gof 
		linktest
	
	est store `v'_cn_nf_ct_ed_pr
	
} // Close loop through variables	

***-----------------------------***
// # CREATE  TABLES
***-----------------------------***

*Output table of all variables - table for paper
outreg2 ///
	[fauci_cn fauci_cn_race_ed_inc fauci_cn_nf_ct_ed_rl ///
	stater_cn stater_cn_race_ed_inc stater_cn_nf_ct_ed_rl ///
	antibody_cn antibody_cn_race_ed_inc antibody_cn_nf_ct_ed_rl ] ///
		using $results/allvars_modelC_ORs.doc, ///
		stats(coef se) ///
		eform /// odds ratios
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace
	
*Extended Online Appendix
outreg2 ///
	[fauci_ex_class_ctrl  ///
	 stater_ex_class_ctrl ///
	 antibody_ex_class_ctrl] ///
		using $results/allvars_extended_news_online_appendix.doc, ///
		stats(coef se) ///
		eform /// odds ratios
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace
	
*Output table with political variable - table for reviewer
	outreg2 ///
	[fauci_cn_nf_ct_ed_pr  ///
	 stater_cn_nf_ct_ed_pr ///
	 antibody_cn_nf_ct_ed_pr] ///
		using $results/politics_for_reviewer.doc, ///
		stats(coef se) ///
		eform /// odds ratios
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace
	
		
*LIKELIHOOD RATIO TESTs
*https://www.stata.com/support/faqs/statistics/likelihood-ratio-test/
/*

foreach v in antibody  fauci  stateresponse { // unemploy
		
	test [`v'_controls = `v'_edu], common nosvyadjust // for use with svy estimation commands
	test [`v'_edu = `v'_edu_news], common nosvyadjust // for use with svy estimation commands
	test [`v'_edu_news =`v'_int_bipoc], common nosvyadjust // for use with svy estimation commands 
	test [`v'_edu_news =`v'_int_income], common nosvyadjust // for use with svy estimation commands
	test [`v'_edu_news = `v'_int_fem], common nosvyadjust // for use with svy estimation commands
}
*/



***--------------------------***

log close ckn`category'`dataset'
exit
