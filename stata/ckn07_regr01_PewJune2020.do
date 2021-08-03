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
capt ssc install svylogitgof, replace

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

local edu_var "i.dG_edu"
fvset base 1 dG_edu  		// ref: less than HS

*set base to international/national or public health
*fvset base 1 dG_cnews		// ref: National / International news outlets
fvset base 4 dG_cnews		// ref: public health
fvset base 7.00  dG_crely 		// ref: public health

fvset base 3 dG_newsfol 	// ref: How closely following news? not too / at all closely


rename stateresponse_c stater_c // shorten variable


***-----------------------------***
// # FINAL MODEL
***-----------------------------***
foreach v in antibody fauci stater   { // 

// # NEWS SOURCE ONLY (BASELINE)

	di in red "Running model A for  `v' "

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: cnews_news
		, or baselevels // report Odds Ratios
	
	est store `v'_modA
	
	svylogitgof

// # NEWS SOURCE + MODERATORS

	di in red "Running model B for  `v'"

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_race  `income_var' `edu_var'  ///
		, or baselevels // report Odds Ratios
		
	est store `v'_modB
	
	svylogitgof
	

// #  NEWS SOURCE + MODERATORS + CONTROLS (incl. HOW CLOSELY FOLLOW NEWS)

	di in red "Running model C for  `v'"

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_race  `income_var'  `edu_var'  /// moderators
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age dB_fem ///
		i.dG_rel ///
		, or baselevels // report Odds Ratios
	
	est store `v'_modC
	
	svylogitgof
	
} // Close loop through variables	



***-----------------------------***
// # CREATE  TABLES
***-----------------------------***

*Output table of all variables - table for paper
outreg2 ///
	[fauci_modA fauci_modB fauci_modC ///
	stater_modA stater_modB stater_modC ///
	antibody_modA antibody_modB antibody_modC ] ///
		using $results/allvars_models_ORs.doc, ///
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





***-----------------------------***
// # ONLINE APPENDIX TABLE A1: NEWS SOURCE (ORIGINAL EXTENDED VARIABLE)
***-----------------------------***


foreach v in antibody fauci stater   { // 

// # NEWS SOURCE ONLY (BASELINE)

	svy: logit `v'_c  ///	
		i.dG_crely ///
		, or baselevels // report Odds Ratios
	
	est store `v'_ex

	
// # EXTENDED NEWS SOURCE + MODERATORS (RACE + INCOME + EDUCATION)

	svy: logit `v'_c  ///	
		i.dG_crely ///
		i.dG_race  `income_var' `edu_var' ///
		, or baselevels // report Odds Ratios
	
	est store `v'_ex_class

	
// # EXTENDED NEWS SOURCE + MODERATORS + CONTROLS 

	svy: logit `v'_c  ///	
		i.dG_crely	///
		i.dG_race  `income_var' `edu_var' ///
		i.dG_newsfol ///
		i.dG_age dB_fem ///
		i.dG_rel ///
		, or baselevels // report Odds Ratios
	
	est store `v'_ex_class_ctrl

} // Close loop through variables	


*Extended Online Appendix A1
outreg2 ///
	[fauci_ex_class_ctrl  ///
	 stater_ex_class_ctrl ///
	 antibody_ex_class_ctrl] ///
		using $results/tableA1_extended.doc, ///
		stats(coef se) ///
		eform /// odds ratios
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace
	

***-----------------------------***			
// # ONLINE APPENDIX A2: POLITICAL PARTY
***-----------------------------***


drop if dG_pol == . /// drop if missing data on politics variable (not dropped previously in descriptives file)

foreach v in antibody fauci stater   { // 

	di in red "Running model including political party for  `v'"

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_race  `income_var'  `edu_var'  /// moderators
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age dB_fem ///
		i.dG_pol ///
		i.dG_rel ///
		, or baselevels // report Odds Ratios
	
	est store `v'_pol
	
	svylogitgof
	
	
} // Close loop through variables	


*Output table with political variable A2
	outreg2 ///
	[fauci_pol  ///
	 stater_pol ///
	 antibody_pol] ///
		using $results/tableA2_politics.doc, ///
		stats(coef se) ///
		eform /// odds ratios
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace
	
***--------------------------***

log close ckn`category'`dataset'
exit
