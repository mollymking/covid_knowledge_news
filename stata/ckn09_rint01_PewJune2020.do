local dataset `"01_PewJune2020"'
local category `"09_rint"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:		Regression Models with Interactions for Online Appendix Table A3
/*  data:    */ di "`dataset'" /* - June Knowledge Questions */

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

capt ssc install estout, replace
capt ssc install outreg2, replace

use $deriv/ckn05_news`dataset'.dta, clear
save $deriv/ckn`category'`dataset'.dta, replace // data that results at end

cd $deriv

*Details on generating LaTeX tables using est and esttab thanks to the following websites:
	*http://repec.sowi.unibe.ch/stata/estout/esttab.html#h-12
	*https://lukestein.github.io/stata-latex-workflows/
	*https://www.jwe.cc/2012/03/stata-latex-tables-estout/
	
***-----------------------------***
// #  INTERACTION MODELS - APPENDIX
***-----------------------------***

// STORE BASE LEVELS for INTERACTIONS

fvset base 0 dB_bipoc
fvset base 1 dG_cnews 	// ref: dB_cnews_news 

local edu_var "dG_edu"
fvset base 1 dG_edu  		// ref: less than HS

local income_var "dG_finc" 	// 
fvset base 1 dG_finc 		// ref: less than $30,000

rename stateresponse_c stater_c // shorten variable


foreach v in  fauci antibody stater { // unemploy 

	drop if `v'_c == 99 // Refused
	drop if `v'_c == 98 // Did not receive question
	drop if covidnewsrel == 98 | covidnewsrel == 99 // refused or Did not receive question 
		// only 48 people


// # NEWS SOURCE ONLY (BASELINE)

	di in red "Running model A for  `v' "

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: cnews_news
		, or baselevels // report Odds Ratios
	
	est store `v'_modA
	
	svylogitgof


// # NEWS SOURCE + MODERATORS

	di in red "Running model B for  `v' with BIPOC race variable"

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		dB_bipoc  `income_var' i.`edu_var'  ///
		, or baselevels // report Odds Ratios
		
	est store `v'_modBbipoc
	
	svylogitgof
	

// #  NEWS SOURCE + MODERATORS + CONTROLS (incl. HOW CLOSELY FOLLOW NEWS)

	di in red "Running model C for  `v' with BIPOC race variable"

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age dB_fem ///
		i.dG_rel ///
		dB_bipoc i.`income_var'  i.`edu_var'  /// moderators
		, or baselevels // report Odds Ratios
	
	est store `v'_modCbipoc
	
	svylogitgof
	
	
// # MODEL - INTERACT: NEWS * BIPOC

	di in red "Running model on `v' for interaction of news and BIPOC status"
	
		svy: logit `v'_c  ///
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age dB_fem ///
		i.dG_rel ///
		i.`income_var'  i.`edu_var'  /// moderators
		dB_bipoc##i.dG_cnews /// ## includes both main effects and interactions
		, or baselevels // report Odds Ratios

	est store `v'_int_NewsBIPOC
		
	svylogitgof
	
*	margins, over(dB_bipoc dG_cnews) expression(exp(xb())) noatlegend

*	margins dB_bipoc, dydx(dG_cnews)


// # MODEL - INTERACT: NEWS * INCOME

	di in red "Running model on `v' for interaction of news and income"
	
		svy: logit `v'_c  ///
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age dB_fem ///
		i.dG_rel ///
		dB_bipoc   i.`edu_var'  /// moderators
		i.`income_var'##i.dG_cnews /// ## includes both main effects and interactions
		, or baselevels // report Odds Ratios

	est store `v'_int_NewsIncome
		
	svylogitgof
	

// # MODEL - INTERACT: NEWS * EDU

	di in red "Running model on `v' for interaction of news and education"
	
		svy: logit `v'_c  ///
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age dB_fem ///
		i.dG_rel ///
		dB_bipoc  i.`income_var'  /// moderators
		i.`edu_var'##i.dG_cnews /// ## includes both main effects and interactions
		, or baselevels // report Odds Ratios

	est store `v'_int_NewsEdu
		
	svylogitgof
	
		
// # MODEL - INTERACT: NEWS * GENDER

	di in red "Running model on `v' for interaction of news and gender"
	
		svy: logit `v'_c  ///
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age  ///
		i.dG_rel ///
		dB_bipoc  i.`income_var' i.`edu_var' /// moderators
		dB_fem##dG_cnews /// ## includes both main effects and interactions
		, or baselevels // report Odds Ratios

	est store `v'_int_NewsGender
		
	svylogitgof
	
/*
*Output table of all variables
	outreg2 ///
	[`v'_modCbipoc `v'_int_NewsBIPOC `v'_int_NewsIncome `v'_int_NewsEdu `v'_int_NewsGender] ///
		using $results/`v'_interactions.doc, ///
		stats(coef se) ///
		eform /// odds ratios
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace
*/			
} // Close loop through variables

*Output results for BIPOC Interactions

	outreg2 ///
	[fauci_modCbipoc fauci_int_NewsBIPOC ///
	 stater_modCbipoc stater_int_NewsBIPOC ///
	 antibody_modCbipoc antibody_int_NewsBIPOC] ///
		using $results/tableA3_all_interactions.doc, ///
		stats(coef se) ///
		eform /// odds ratios
		level(95) symbol(***, **, *) alpha(0.001, 0.01, 0.05) ///
		replace

***--------------------------***

log close ckn`category'`dataset'
exit
