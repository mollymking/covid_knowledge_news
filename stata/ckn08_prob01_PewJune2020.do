local dataset `"01_PewJune2020"'
local category `"08_prob"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:		Predicted Probabilities - June Knowledge Questions
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

***-----------------------------***
// # NO INTERACTIONS - HISTOGRAM OF RACE AND NEWS
***-----------------------------***
*https://journals.sagepub.com/doi/pdf/10.1177/1536867X0500500111

foreach v in  antibody fauci stateresponse  { //   unemploy 

	drop if `v'_c == 99 // Refused
	drop if `v'_c == 98 // Did not receive question
	drop if covidnewsrel == 98 | covidnewsrel == 99 // refused or Did not receive question 

svy: logit `v'_c  dB_fem ///
	dB_age_30_49 dB_age_50_64 dB_age_65p ///
	`income_var' ///
	dB_rwhite dB_rblack dB_rasian dB_rhisp dB_rother ///
	dB_edu_lHS dB_edu_sCol dB_edu_col dB_edu_grad  ///
	dB_cnews_local dB_cnews_politicians dB_cnews_pubhealth dB_cnews_informal /// comparison: cnews_news
	, baselevels 

*this command does not work for some reason:
*prtab dB_rblack dB_rasian dB_rhisp dB_rother, rest(mean)

gen  `v'_race_news = .
gen  `v'_race_news_cilo = .
gen  `v'_race_news_cihi = .

foreach racevar of varlist dB_rwhite dB_rblack dB_rasian dB_rhisp dB_rother {
	foreach newsvar of varlist dB_cnews_local dB_cnews_politicians dB_cnews_pubhealth dB_cnews_informal {
		prvalue, x(`racevar'=1 `newsvar'=1) rest(mean) brief
				
		*return list
		replace  `v'_race_news = r(p1) 			if `racevar' == 1 & `newsvar' == 1
		replace  `v'_race_news_cilo = r(p1_lo)	if `racevar' == 1 & `newsvar' == 1
		replace  `v'_race_news_cihi = r(p1_hi)	if `racevar' == 1 & `newsvar' == 1
	 
	} // close newsvar loop
	
	prvalue, x(`racevar'=1 dB_cnews_local=0 dB_cnews_politicians=0 dB_cnews_pubhealth=0 dB_cnews_informal=0) ///
		rest(mean) brief	

	replace `v'_race_news = r(p1) if `racevar' == 1 & ///
		dB_cnews_local==0 & dB_cnews_politicians==0 & dB_cnews_pubhealth==0 & dB_cnews_informal==0
	replace `v'_race_news_cilo = r(p1_lo) if `racevar' == 1 & ///
		dB_cnews_local==0 & dB_cnews_politicians==0 & dB_cnews_pubhealth==0 & dB_cnews_informal==0
	replace `v'_race_news_cihi = r(p1_hi) if `racevar' == 1 & ///
		dB_cnews_local==0 & dB_cnews_politicians==0 & dB_cnews_pubhealth==0 & dB_cnews_informal==0
	
} // close racevar loop
} // close loop through fauci antibody stateresponse	

**Next step: also store confidence intervals

label define media_source 1 "Intl/Natl" 2 "Local" 3 "Politicians" 4 "Public Health" 5 "Informal"
lab val dG_cnews media_source

*make table of predicted probability by race and news source, at mean income:
foreach v in  antibody fauci stateresponse  { //    unemploy 
	table dG_cnews dG_race , contents(mean `v'_race_news mean `v'_race_news_cihi mean `v'_race_news_cilo)

	
//HISTOGRAM

*need to add CIs: https://stats.idre.ucla.edu/stata/faq/how-can-i-make-a-bar-graph-with-error-bars/

graph bar `v'_race_news, ///
	over(dG_race, ///
		label(labcolor(black) angle(45) labsize(small)) ///  gap (between group bars); group label(color; angle; size; gap between label and graph);
		axis(outergap(2))) /// axis(line color; gap between label and legend)) 
		bargap(0) outergap(15) /// gap between within group bars; gap outside first/last group
	asyvars ///
	over(dG_cnews) ///
	bar(1, fcolor("57 118 104") fintensity(inten60) lcolor("57 118 104") lwidth(small)) /// Bar(fill color, fill intensity, line color, line width)
	bar(2, fcolor("188 121 18") fintensity(inten60) lcolor("188 121 18") lwidth(small)) /// fill intensity = 60%
	bar(3, fcolor("149 158 74") fintensity(inten60) lcolor("149 158 74") lwidth(small)) ///
	bar(4, fcolor("93 164 181") fintensity(inten60) lcolor("93 164 181") lwidth(small)) ///
	plotregion(fcolor("233 233 234") lcolor(white)) /// graph plot(fill color; line color)
	ytitle("Predicted Probability of Answering Correctly" , color("147 149 152")) /// y-axis: title(text; text color) 
	ylabel(0(.1)1, gmax labcolor("`DkGrey'") tlcolor("`DkGrey'") tlwidth(medium) glcolor(white) glwidth(medium)) yscale(lcolor("`DkGrey'")) /// y-ticks: label(scale, max line, label color, tick color; tick width; grid color; grid width); axis color
	legend(on order(1 "Non-Hispanic White" 2 "Black" 3 "Asian" 4 "Hispanic" ) nostack rows(1) size(small) color(black) margin(small) nobox region(fcolor(white) lcolor(white)))

graph export  "/Users/mollymking/Documents/SocResearch/COVID_Knowledge_News/covid_knowledge_news/figures/pp_`v'_inc_news.jpg", ///
	as(jpg) name("Graph") quality(100) replace

} // close loop through fauci antibody stateresponse	


***-----------------------------***
// # INCOME
***-----------------------------***
/*
foreach v in  fauci antibody stateresponse  { // unemploy 

	drop if `v'_c == 99 // Refused
	drop if `v'_c == 98 // Did not receive question
	drop if covidnewsrel == 98 | covidnewsrel == 99 // refused or Did not receive question 

svy: logit `v'_c  i.dG_age  dB_fem i.dG_edu   ///
	dB_bipoc ///
	c.`income_var'##i.dG_cnews /// ## includes both main effects and interactions
	, or baselevels // report Odds Ratios

} // close loop through fauci antibody stateresponse	
*/
***--------------------------***

log close ckn`category'`dataset'
exit
