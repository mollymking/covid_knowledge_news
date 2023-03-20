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

use $deriv/ckn06_desc`dataset'.dta, clear
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

set scheme reportcool

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


// STORE BASE LEVELS

fvset base 0 dB_bipoc
fvset base 1 dG_age	 // ref: 18-29

local income_var "dG_finc" 	// 
fvset base 1 dG_finc 		// ref: less than $30,000

fvset base 1 dG_cnews 		// ref: dB_cnews_news 

local edu_var "dG_edu"
fvset base 1 dG_edu  		// ref: less than HS

*set base to international/national or public health
fvset base 4 dG_cnews		// ref: public health
fvset base 3 dG_newsfol 	// ref: How closely following news? not too / at all closely



***-----------------------------***
// # NO INTERACTIONS - HISTOGRAM OF RACE 
***-----------------------------***
*https://journals.sagepub.com/doi/pdf/10.1177/1536867X0500500111

foreach v in  antibody fauci stateresponse  { //   

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age dB_fem i.dG_race  i.`income_var'   ///
		i.`edu_var'  ///
		i.dG_rel ///
		, baselevels // report Odds Ratios
		
	margins dG_race
	return list /// see what is being stored
	
	cap loc `v'_white_pp   = r(table)[1,1]
	cap loc `v'_white_cilo = r(table)[5,1]
	cap loc `v'_white_cihi = r(table)[6,1]
	di in red "White PP: " ``v'_white_pp' " CILO "``v'_white_cilo' " CIHI " ``v'_white_cihi' 
	
	cap loc `v'_black_pp   = r(table)[1,2]
	cap loc `v'_black_cilo = r(table)[5,2]
	cap loc `v'_black_cihi = r(table)[6,2]

	cap loc `v'_asian_pp   = r(table)[1,3]
	cap loc `v'_asian_cilo = r(table)[5,3]
	cap loc `v'_asian_cihi = r(table)[6,3]
	di in red "Asian PP: " ``v'_asian_pp' " CILO "``v'_asian_cilo' " CIHI " ``v'_asian_cihi' 

	cap loc `v'_hisp_pp   = r(table)[1,4]
	cap loc `v'_hisp_cilo = r(table)[5,4]
	cap loc `v'_hisp_cihi = r(table)[6,4]
	
	cap loc `v'_other_pp   = r(table)[1,5]
	cap loc `v'_other_cilo = r(table)[5,5]
	cap loc `v'_other_cihi = r(table)[6,5]
	

	gen `v'_race_pp = .
	gen `v'_race_cilo = .
	gen `v'_race_cihi = .
	
	foreach racevar in white black asian hisp other {
		replace  `v'_race_pp   = ``v'_`racevar'_pp'		if dB_r`racevar' == 1 
		di in red "PP for `racevar ' ``v'_`race'_pp'"
	
		replace  `v'_race_cilo = ``v'_`racevar'_cilo'	if dB_r`racevar' == 1 
		di in red "CILO for `racevar ' ``v'_`race'_cilo'"
		
		replace  `v'_race_cihi = ``v'_`racevar'_cihi'	if dB_r`racevar' == 1 
		di in red "CIHI for `racevar ' ``v'_`race'_cihi'"
	} // close racevar loop
} // close loop through fauci antibody stateresponse

	 	
// HISTOGRAM Without CIs
/*
foreach v in  antibody fauci stateresponse  { //   
graph bar `v'_race_pp, ///
	over(dG_race, ///
		label(labcolor(black) angle(45) labsize(small)) ///  gap (between group bars); group label(color; angle; size; gap between label and graph);
		axis(outergap(2))) /// axis(line color; gap between label and legend)) 
		bargap(0) outergap(15) /// gap between within group bars; gap outside first/last group
	asyvars ///
	bar(1, fcolor(`Teal') fintensity(inten60) lcolor(`Teal') lwidth(small)) /// Bar(fill color, fill intensity, line color, line width)
	bar(2, fcolor(`Gold') fintensity(inten60) lcolor(`Gold') lwidth(small)) /// fill intensity = 60%
	bar(3, fcolor(`Green') fintensity(inten60) lcolor(`Green') lwidth(small)) ///
	bar(4, fcolor(`Blue') fintensity(inten60) lcolor(`Blue') lwidth(small)) ///
	bar(5, lwidth(small)) ///
	plotregion(fcolor("233 233 234") lcolor(white)) /// graph plot(fill color; line color)
	ytitle("Predicted Probability of Answering Correctly" , color("147 149 152")) /// y-axis: title(text; text color) 
	ylabel(0(.1)1, gmax labcolor("`DkGrey'") tlcolor("`DkGrey'") tlwidth(medium) glcolor(white) glwidth(medium)) yscale(lcolor("`DkGrey'")) /// y-ticks: label(scale, max line, label color, tick color; tick width; grid color; grid width); axis color
	legend(on order(1 "Non-Hispanic White" 2 "Black" 3 "Asian" 4 "Hispanic" 5 "Other" ) nostack rows(1) size(small) color(black) margin(small) nobox region(fcolor(white) lcolor(white)))

graph export  "/Users/mollymking/Documents/SocResearch/COVID_Knowledge_News/covid_knowledge_news/figures/`v'_pp_race.jpg", ///
	as(jpg) name("Graph") quality(100) replace

} // close loop through fauci antibody stateresponse

*/


// HISTOGRAM with CIs
* https://stats.idre.ucla.edu/stata/faq/how-can-i-make-a-bar-graph-with-error-bars/
	
	generate knowrace = dG_race    if fauci_c == 1
	replace  knowrace = dG_race+5  if stateresponse_c == 1
	replace  knowrace = dG_race+10 if antibody_c == 1
	sort knowrace
	list knowrace dG_race
	
	generate race_pp = .
	replace race_pp = fauci_race_pp if fauci_c == 1
	replace race_pp = stateresponse_race_pp if stateresponse_c == 1
	replace race_pp = antibody_race_pp if antibody_c == 1
	
	generate race_cihi = .
	replace race_cihi = fauci_race_cihi if fauci_c == 1
	replace race_cihi = stateresponse_race_cihi if stateresponse_c == 1
	replace race_cihi = antibody_race_cihi if antibody_c == 1
	
	generate race_cilo = .
	replace race_cilo = fauci_race_cilo if fauci_c == 1
	replace race_cilo = stateresponse_race_cilo if stateresponse_c == 1
	replace race_cilo = antibody_race_cilo if antibody_c == 1	
	
drop if dG_race == 5
	
twoway (bar race_pp knowrace if dG_race==1) ///
       (bar race_pp knowrace if dG_race==2) ///
       (bar race_pp knowrace if dG_race==3) ///
       (bar race_pp knowrace if dG_race==4) ///
	   (rcap race_cihi race_cilo  knowrace), ///
		ylabel(0(.1)1, gmax labcolor("`DkGrey'") tlcolor("`DkGrey'") tlwidth(medium) glcolor(white) glwidth(medium)) yscale(lcolor("`DkGrey'")) /// y-ticks: label(scale, max line, label color, tick color; tick width; grid color; grid width); axis color
		xlabel( 2.5 "Fauci" 7.5 "State Response" 12.5 "Antibody", noticks) ///
		xtitle("COVID-19 Knowledge Question") ///
		ytitle("Predicted Probability of Answering Correctly" , color("147 149 152")) /// y-axis: title(text; text color) 
       legend(on order(1 "Non-Hispanic White" 2 "Black" 3 "Asian" 4 "Hispanic") nostack rows(1) size(small) color(black) margin(small) nobox region(fcolor(white) lcolor(white))) ///
		scheme(reportcool)
	
/*	
graph export  "/Users/mollymking/Documents/SocResearch/COVID_Knowledge_News/covid_knowledge_news/figures/pp_race.jpg", ///
	as(jpg) name("Graph") quality(100) replace
*/
***-----------------------------***
// # NO INTERACTIONS - MARGINS of INCOME and CORRECT ANSWERS
***-----------------------------***

foreach v in  antibody fauci stateresponse  { //   

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age dB_fem i.dG_race  i.`income_var'   ///
		i.`edu_var'  ///
		i.dG_rel ///
		, baselevels // report Odds Ratios
		
	margins `income_var', saving($temp/file_pp_`v'_inc.dta, replace)
	
	*marginsplot
	
} // close loop through fauci antibody stateresponse	

cap ssc install combomarginsplot
combomarginsplot ///
	$temp/file_pp_fauci_inc $temp/file_pp_stateresponse_inc $temp/file_pp_antibody_inc, ///
    labels("Fauci" "State Response" "Antibody") ///
	file1opts(msymbol(O)) /// formatting for 1st file (fauci)
	file2opts(msymbol(D)) /// formatting for 2nd file (state response)
	file3opts(msymbol(S)) ///
	xtitle("Family Income") ///
	xlabel(1 "<$30,000" 2 "$30,000-$50,000" 3 "$50,000-$75,000" 4 "$75,000-$100,000" ///
		5 "$100,000-$150,000" 6 "$150,000+" ///
		, gmax angle(45)) ///
	ytitle("Predicted Probability" "of Answering Correctly" , color("147 149 152")) /// y-axis: title(text; text color) 
	ylabel(.4(.1).9, gmax labcolor("`DkGrey'") tlcolor("`DkGrey'") tlwidth(medium) glcolor(white) glwidth(medium)) yscale(lcolor("`DkGrey'")) /// y-ticks: label(scale, max line, label color, tick color; tick width; grid color; grid width); axis color
	title("") ///  
		scheme(reportcool)
/*
	graph export "/Users/mollymking/Documents/SocResearch/COVID_Knowledge_News/covid_knowledge_news/figures/pp_inc.jpg", ///
	as(jpg) name("Graph") quality(100) replace
*/	

***-----------------------------***
// # NO INTERACTIONS - MARGINS of EDUCATION and CORRECT ANSWERS
***-----------------------------***

foreach v in  antibody fauci stateresponse  { //   

	svy: logit `v'_c  ///
		i.dG_cnews /// comparison: international/national
		i.dG_newsfol /// comparison: do not closely follow
		i.dG_age dB_fem i.dG_race  i.`income_var'   ///
		i.`edu_var'  ///
		i.dG_rel ///
		, baselevels // report Odds Ratios
		
	margins `edu_var', saving($temp/file_pp_`v'_edu.dta, replace)
	
	*marginsplot
	
	*graph export "/Users/mollymking/Documents/SocResearch/COVID_Knowledge_News/covid_knowledge_news/figures/pp_`v'_edu.jpg", as(jpg) name("Graph") quality(100) replace
	
} // close loop through fauci antibody stateresponse	




cap ssc install combomarginsplot
combomarginsplot ///
	$temp/file_pp_fauci_edu $temp/file_pp_stateresponse_edu $temp/file_pp_antibody_edu, ///
    labels("Fauci" "State Response" "Antibody") ///
	file1opts(msymbol(O)) /// formatting for 1st file (fauci)
	file2opts(msymbol(D)) /// formatting for 2nd file (state response)
	file3opts(msymbol(S)) ///
	xtitle("Educational Attainment") ///
	xlabel(1 "<High School" 2 "High School" 3 "Some College" 4 "College" 5 "Graduate" ///
		, gmax) ///
	ytitle("Predicted Probability" "of Answering Correctly" , color("147 149 152")) /// y-axis: title(text; text color) 
	ylabel(.4(.1).9, gmax labcolor("`DkGrey'") tlcolor("`DkGrey'") tlwidth(medium) glcolor(white) glwidth(medium)) yscale(lcolor("`DkGrey'")) /// y-ticks: label(scale, max line, label color, tick color; tick width; grid color; grid width); axis color
	title("") ///  
		scheme(reportcool)

/*
	graph export "/Users/mollymking/Documents/SocResearch/COVID_Knowledge_News/covid_knowledge_news/figures/pp_edu.jpg", ///
	as(jpg) name("Graph") quality(100) replace
*/	

***--------------------------***

log close ckn`category'`dataset'
exit
