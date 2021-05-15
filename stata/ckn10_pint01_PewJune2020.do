local dataset `"01_PewJune2020"'
local category `"10_pint"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:		Predicted Probabilities - Interaction Models
/*  data:    */ di "`dataset'" /*- June Knowledge Questions */

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

use $deriv/ckn05_news`dataset'.dta, clear
save $deriv/ckn`category'`dataset'.dta, replace // data that results at end

cd $deriv

***--------------------------***
// SET LOCALS
***--------------------------***
// correct/not correct variables set
if "`CD'" == "C" {
	local title "correctness"
	local coef_meaning "Correct"
	local answer "Correctly"
}

// don't know variables set
if "`CD'" == "D" {
	local title "certainty"
	local coef_meaning "Uncertain"
	local answer "Don't Know"
}

// Color locals
local Teal "57 118 104"
local Gold "188 121 18"
local Green "149 158 74"
local Blue "93 164 181"
local LtGrey "233 233 234"
local DkGrey "147 149 152"

// Graph fonts
local graphfont "Palatino"
graph set window fontface "`graphfont'"
graph set window fontfaceserif "`graphfont'"
graph set window /*echo back preferences*/


***-----------------------------***
// # INTERACTIONS / MARGINS
***-----------------------------***

// STORE BASE LEVELS for INTERACTIONS

fvset base 0 dB_bipoc
fvset base 1 dG_cnews // ref: dB_cnews_news 
fvset base 2 dG_edu  // ref: HS
fvset base 1 dG_age	 // ref: 18-29

local income_var  dV_finc_ln // 

*https://stats.idre.ucla.edu/stata/faq/how-can-i-graph-the-results-of-the-margins-command-stata-12/

/*
Adjusted predicted probability of y = 1 for each level of a when x is at its mean after
logit y a##c.x
margins a, atmeans

Adjusted predicted probability for each level of the interaction of a and b, holding x at 25, after
logit y a##b##c.x
margins a#b, at(x=25)

Adjusted prediction for each level of a when x = 25 and b = 1
margins a, at(x=25 b=1)
*/
*Also
*https://www.stata.com/statalist/archive/2013-01/msg00293.html


***-----------------------------***
// # INCOME * LOCAL NEWS MARGINS
***-----------------------------***
/*
foreach v in  stateresponse { //  antibody  unemploy 

	drop if `v'_c == 99 // Refused
	drop if `v'_c == 98 // Did not receive question
	drop if covidnewsrel == 98 | covidnewsrel == 99 // refused or Did not receive question 

	svy: logit `v'_c  i.dG_age  dB_fem i.dG_edu   ///
	dB_bipoc ///
	c.`income_var'##i.dG_cnews /// ## includes both main effects and interactions
	, or baselevels // report Odds Ratios
	
*predict `v'_pp

*summarize `v'_pp
*summarize `v'_c

margins dG_cnews,  at(`income_var'=(-7(1)7)) vsquish
marginsplot
*shows significant interaction  of income and local news
*graph export  "/Users/mollymking/Documents/SocResearch/COVID_Knowledge_News/covid_knowledge_news/figures/pp_stateresponse_inc_news.jpg", ///
	as(jpg) name("Graph") quality(90)

} // close loop through fauci antibody stateresponse	
*/




***--------------------------***

log close ckn`category'`dataset'
exit
