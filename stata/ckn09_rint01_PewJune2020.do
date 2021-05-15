local dataset `"01_PewJune2020"'
local category `"09_rint"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:		Regression Models with Interactions
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
fvset base 1 dG_cnews // ref: dB_cnews_news 
fvset base 2 dG_edu  // ref: HHS

local income_var  dV_finc_ln // l

foreach v in  fauci antibody stateresponse  { // unemploy 

	drop if `v'_c == 99 // Refused
	drop if `v'_c == 98 // Did not receive question
	drop if covidnewsrel == 98 | covidnewsrel == 99 // refused or Did not receive question 
		// only 48 people
/*
// # BASIC MODEL - CONTROLS ONLY
	svy: logit `v'_c  dB_fem i.dG_age `income_var'  ///
	dB_bipoc ///
	, or baselevels // report Odds Ratios
	
	est store `v'_controls

// # MODEL - ADD IN EDUCATION
	svy: logit `v'_c  dB_fem i.dG_age `income_var'  i.dG_edu ///
	dB_bipoc ///
	, or baselevels // report Odds Ratios
		
	est store `v'_edu


// # MODEL - ADD IN NEWS
		
	svy: logit `v'_c    dB_bipoc i.dG_age  dV_finc_1k dB_fem  `edu_vars'  ///
	dB_crely_international dB_crely_local dB_crely_trump dB_crely_biden /// comparison: crely_national 
	dB_crely_politicians dB_crely_ph dB_crely_friends dB_crely_neighbor dB_crely_online, ///
	or // report Odds Ratios

	est store `v'_edu_news	


// # MODEL - NEWS SHORT ALTERNATIVE
		
	svy: logit `v'_c  dB_fem  i.dG_age  `income_var'  i.dG_edu ///
	dB_bipoc ///
	i.dG_cnews /// comparison: cnews_news
	, or baselevels // report Odds Ratios
		
	est store `v'_edu_news
			
// # MODEL - ADD IN NEWS DIFFICULT
		
	svy: logit `v'_c   dB_bipoc i.dG_age  dV_finc_1k dB_fem  `edu_vars'  ///
	dB_crely_international dB_crely_national dB_crely_trump dB_crely_biden /// comparison: crely_local
	dB_crely_politicians dB_crely_ph dB_crely_friends dB_crely_neighbor dB_crely_online ///
	dB_cinfodiff, ///
		or // report Odds Ratios

	est store `v'_edu_news_difficult	

// # MODEL - ADD IN INTERACTIONS BIPOC
	
	svy: logit `v'_c  i.dG_age  dB_fem  `income_var'  i.dG_edu  ///
	dB_bipoc##i.dG_cnews /// ## includes both main effects and interactions
	, or baselevels // report Odds Ratios
	

	est store `v'_int_bipoc
	
	*test dG_race[2] = , common nosvyadjust 
	
*	margins, over(dB_bipoc dG_cnews) expression(exp(xb())) noatlegend

*	margins dB_bipoc, dydx(dG_cnews)

*/
// # MODEL - ADD IN INTERACTIONS INCOME
		
	svy: logit `v'_c  i.dG_age  dB_fem i.dG_edu   ///
	dB_bipoc ///
	c.`income_var'##i.dG_cnews /// ## includes both main effects and interactions
	, or baselevels // report Odds Ratios
	
	est store `v'_int_income
	
// # MODEL - test INTERACTIONS INCOME without education
		
	svy: logit `v'_c  i.dG_age  dB_fem   /// i.dG_edu
	dB_bipoc ///
	c.`income_var'##i.dG_cnews /// ## includes both main effects and interactions
	, or baselevels // report Odds Ratios
	
	est store `v'_int_inc_noedu
/*	
// # MODEL - ADD IN INTERACTIONS EDUCATION
		
	svy: logit `v'_c  i.dG_age  dB_fem `income_var'   ///
	dB_bipoc ///
	i.dG_edu##i.dG_cnews /// ## includes both main effects and interactions
	, or baselevels // report Odds Ratios
	

	est store `v'_int_income
	
// # MODEL - ADD IN INTERACTIONS GENDER
		
	svy: logit `v'_c  i.dG_age `income_var'  i.dG_edu  ///
	dB_bipoc ///
	dB_fem##i.dG_cnews /// ## includes both main effects and interactions
	, or baselevels // report Odds Ratios
	

	est store `v'_int_fem	

// # CREATE LATEX TABLE

	esttab `v'_controls `v'_edu `v'_edu_news `v'_int_bipoc `v'_int_income `v'_int_fem ///
		using $results/`v'LOs_interactions.tex, ///
		replace f ///
		label booktabs b(3) p(3) eqlabels(none) alignment(S S) ///
		collabels("\multicolumn{1}{c}{$\beta$ / SE}") ///
		star(* 0.05 ** 0.01 *** 0.001) ///
		cells("b(fmt(3)star)" "se(fmt(3)par)") ///
		stats(N aic pr, fmt(0 3) layout("\multicolumn{1}{c}{@}") ///
			labels(`"Observations"' `"AIC"' `"Baseline predicted probability"'))
		*refcat(dB_bipoc "\emph{BIPOC}" dB_fem "\emph{Gender}" dG_age "\emph{Age}" ///
			*dV_finc_ln "\emph{Family Income (Ln)}"  ///
			*dG_edu "\emph{Education}" dG_cnews "\emph{News Outlet}") ///
			
*/		
} // Close loop through variables

