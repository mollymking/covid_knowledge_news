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


drop if antibody_c == 99 // Refused
drop if `v'_c == 98 // Did not receive question
drop if covidnewsrel == 98 | covidnewsrel == 99 // refused or Did not receive question 
	// only 48 people	


		
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
		i.dG_race  `income_var' i.dG_edu  ///
		, or baselevels // report Odds Ratios
	
	est store `v'_ex_class

	
// # A -  EXTENDED NEWS SOURCE + CONTROLS + EDUCATION + RELIGION

	svy: logit `v'_c  ///	
		i.dG_crely	///
		i.dG_race  `income_var' i.dG_edu  ///
		dG_newsfol ///
		i.dG_age dB_fem  ///
		, or baselevels // report Odds Ratios
	
	est store `v'_ex_class_ctrl


***-----------------------------***
// # MODEL B: COMPRESSED NEWS SOURCE
***-----------------------------***

// # BASIC MODEL B -  NEWS SOURCE ONLY

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: cnews_news
		, or baselevels // report Odds Ratios
	
	est store `v'_cn
	
// # MODEL B + CONTROLS 
	svy: logit `v'_c ///
		i.dG_cnews /// comparison: international/national
		dB_fem i.dG_age `income_var' i.dG_race ///
		, or baselevels // report Odds Ratios
	
		estat gof 
		linktest
	
	est store `v'_cn_ct

// # MODEL B + CONTROLS + ADD IN EDUCATION
	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		dB_fem i.dG_age `income_var' i.dG_race ///
		i.dG_edu ///
		, or baselevels // report Odds Ratios
		
		estat gof 
		linktest
		
	est store `v'_cn_ct_ed

*/
	
***-----------------------------***
// # MODEL C: NEWS SOURCE + HOW CLOSELY FOLLOW NEWS
***-----------------------------***

// # BASIC MODEL B -  NEWS SOURCE ONLY

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: cnews_news
		, or baselevels // report Odds Ratios
	
	est store `v'_cn

// # BASIC MODEL C -  NEWS SOURCE + HOW CLOSELY FOLLOW NEWS

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		, or baselevels // report Odds Ratios

		estat gof 
		linktest
	
	est store `v'_cn_nf

	
// # C - NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + CONTROLS + EDUCATION		

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age  dB_fem i.dG_race  `income_var'  ///
		`edu_var'  ///
		, or baselevels // report Odds Ratios
		
		estat gof 
		linktest
	
	est store `v'_cn_nf_ct_ed
/*
// # C - NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + CONTROLS + EDUCATION + POLITICAL PARTY	+ RELIGION	

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
*/
// # C - NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + CONTROLS + EDUCATION + RELIGION	

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_race  `income_var'   ///
		`edu_var'  ///
		, or baselevels // report Odds Ratios
		
		estat gof 
		linktest
	
	est store `v'_cn_race_ed_inc
	

// # C - NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + CONTROLS + EDUCATION + RELIGION	

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
	
/*			
***-----------------------------***			
// # MODEL D: NEWS SOURCE + HOW CLOSELY FOLLOW NEWS +  NEWS DIFFICULTY
***-----------------------------***

// # D - NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + NEWS DIFFICULTY 

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		dB_cinfodiff ///
		, or baselevels // report Odds Ratios
		
		estat gof 
		linktest
	
	est store `v'_cn_nf_df

// # D - NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + NEWS DIFFICULTY + CONTROLS + EDUCATION

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		dB_cinfodiff ///
		i.dG_race i.dG_age  `income_var' dB_fem  ///
		`edu_var' ///
		, or baselevels // report Odds Ratios
		
		estat gof 
		linktest
	
	est store `v'_cn_nf_df_ct_ed

// # D - NEWS SOURCE + HOW CLOSELY FOLLOW NEWS + NEWS DIFFICULTY + CONTROLS + EDUCATION + POLITICAL PARTY+ RELIGION

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		dB_cinfodiff ///
		i.dG_race i.dG_age  `income_var' dB_fem  ///
		`edu_var' ///
		i.dG_pol ///
		i.dG_rel ///
		, or baselevels // report Odds Ratios
		
		estat gof 
		linktest
	
	est store `v'_cn_nf_df_ct_ed_pr

	*/
} // Close loop through variables	

***-----------------------------***
// # CREATE  TABLES
***-----------------------------***
/*
foreach v in antibody fauci stater   { // 
	
	
	*Model A
	outreg2 [`v'_cn  `v'_cr	`v'_cr_ct_ed] ///
		using $results/`v'_modelA_ORs.doc, ///
		stats(coef se) ///
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace
	
	*Model B
	outreg2 [`v'_cn  `v'_cn_ct `v'_cn_ct_ed]  ///
	using $results/`v'_modelA_ORs.doc, ///
		stats(coef se) ///
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace

	
	*Model C
	outreg2 [`v'_cn  `v'_cn_nf  `v'_cn_nf_ct_ed  `v'_cn_nf_ct_ed_rl] ///
		stats(coef se)  ///
		 eform /// odds ratios
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace
 
	*Model D
	outreg2 [`v'_cn `v'_cn_nf_df `v'_cn_nf_df_ct_ed `v'_cn_nf_df_ct_ed_rl] ///
		using $results/`v'_modelD_ORs.doc, ///
		stats(coef se) ///
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace	

	
} // Close loop through variables	
*/	

*Output table of all variables
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
