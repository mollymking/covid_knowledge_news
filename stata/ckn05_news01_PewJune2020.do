local dataset `"01_PewJune2020"'
local category `"05_news"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:     	Create News Variables - June Knowledge Questions
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

use $deriv/ckn04_inc`dataset'.dta, clear
save $deriv/ki`category'`dataset'.dta, replace // data that results at end


***-----------------------------***
// COVIDNEWSRELY_w66
***-----------------------------***
*And which of these sources do you RELY ON MOST for news about the coronavirus outbreak??
	*1 International news outlets
	*2 National news outlets
	*3 Local news outlets
	*4 Donald Trump and his coronavirus task force
	*5 Joe Biden and his campaign
	*6 State and local elected officials and their offices
	*7 Public health organizations and officials
	*8 Friends, family and neighbors
	*9 Community or neighborhood newsletter or Listserv
	*10 Online forums or discussion groups

tab covidnewsrely_w66, m
tab covidnewsrely_w66, m nolabel

clonevar dG_crely = covidnewsrely_w66 
	replace dG_crely = . if covidnewsrely_w66 == 98 | /// Did not receive question
	covidnewsrely_w66 == 99 | /// Refused
	covidnewsrely_w66 == . // Missing

label define dB_source 0 "0_Not source" 1 "1_Main source"

// International news
local source "international"
local source_code = 1
local source_long "International News Outlets"
include $stata/ckn05_news00_crely.doi

// National news
local source "national"
local source_code = 2
local source_long "National News Outlets"
include $stata/ckn05_news00_crely.doi

// Local news
local source "local"
local source_code = 3
local source_long "Local News Outlets"
include $stata/ckn05_news00_crely.doi

// Donald Trump and his coronavirus task force
local source "trump"
local source_code = 4
local source_long "Trump / COVID task force"
include $stata/ckn05_news00_crely.doi

// Joe Biden and his campaign
local source "biden"
local source_code = 5
local source_long "Biden and his campaign"
include $stata/ckn05_news00_crely.doi

// State and local elected officials and their offices
local source "politicians"
local source_code = 6
local source_long "State and local elected officials"
include $stata/ckn05_news00_crely.doi

// Public health organizations and officials
local source "ph"
local source_code = 7
local source_long "Public health organizations and officials"
include $stata/ckn05_news00_crely.doi

// Friends, family and neighbors
local source "friends"
local source_code = 8
local source_long "Friends, family and neighbors"
include $stata/ckn05_news00_crely.doi

// Community or neighborhood newsletter or Listserv
local source "neighbor"
local source_code = 9
local source_long "Community or neighborhood newsletter or Listserv"
include $stata/ckn05_news00_crely.doi

// Online forums or discussion groups
local source "online"
local source_code = 10
local source_long "Online forums or discussion groups"
include $stata/ckn05_news00_crely.doi
	
***-----------------------------***
// SOURCES LUMPED TOGETHER
***-----------------------------***

*News 
	*1 International news outlets
	*2 National news outlets
*Local
	*3 Local news outlets
*Politicians
	*4 Donald Trump and his coronavirus task force
	*5 Joe Biden and his campaign
	*6 State and local elected officials and their offices
*Public Health
	*7 Public health organizations and officials
*Informal Networks
	*8 Friends, family and neighbors
	*9 Community or neighborhood newsletter or Listserv
	*10 Online forums or discussion groups

local short "news"
gen dB_cnews_`short' = 0
replace dB_cnews_`short' = 1 if covidnewsrely_w66 == 1 |  covidnewsrely_w66 == 2
replace dB_cnews_`short' = . if covidnewsrely_w66 == 98 | /// Did not receive question
	covidnewsrely_w66 == 99 | /// Refused
	covidnewsrely_w66 == . // Missing
label var dB_cnews_`short' "International / national news- Source relies most on for news about coronavirus outbreak"

local short "local"
gen dB_cnews_`short' = 0
replace dB_cnews_`short' = 1 if covidnewsrely_w66 == 3
replace dB_cnews_`short' = . if covidnewsrely_w66 == 98 | /// Did not receive question
	covidnewsrely_w66 == 99 | /// Refused
	covidnewsrely_w66 == . // Missing
label var dB_cnews_`short' "`short' - Source relies most on for news about coronavirus outbreak"

local short "politicians"
gen dB_cnews_`short' = 0
replace dB_cnews_`short' = 1 if covidnewsrely_w66 == 4 |  covidnewsrely_w66 == 5 |  covidnewsrely_w66 == 6
replace dB_cnews_`short' = . if covidnewsrely_w66 == 98 | /// Did not receive question
	covidnewsrely_w66 == 99 | /// Refused
	covidnewsrely_w66 == . // Missing
label var dB_cnews_`short' "`short' - Source relies most on for news about coronavirus outbreak"

local short "pubhealth"
gen dB_cnews_`short' = 0
replace dB_cnews_`short' = 1 if covidnewsrely_w66 == 7
replace dB_cnews_`short' = . if covidnewsrely_w66 == 98 | /// Did not receive question
	covidnewsrely_w66 == 99 | /// Refused
	covidnewsrely_w66 == . // Missing
label var dB_cnews_`short' "`short' - Source relies most on for news about coronavirus outbreak"

local short "informal"
gen dB_cnews_`short' = 0
replace dB_cnews_`short' = 1 if covidnewsrely_w66 == 8 |  covidnewsrely_w66 == 9 |  covidnewsrely_w66 == 10
replace dB_cnews_`short' = . if covidnewsrely_w66 == 98 | /// Did not receive question
	covidnewsrely_w66 == 99 | /// Refused
	covidnewsrely_w66 == . // Missing
label var dB_cnews_`short' "`short' - Source relies most on for news about coronavirus outbreak"

gen dG_cnews = 0
replace dG_cnews = . if covidnewsrely_w66 == 98 | /// Did not receive question
	covidnewsrely_w66 == 99 | /// Refused
	covidnewsrely_w66 == . // Missing
replace dG_cnews = 1 if dB_cnews_news == 1 // International or national
replace dG_cnews = 2 if dB_cnews_local == 1 // Local news
replace dG_cnews = 3 if dB_cnews_politicians == 1 // politicians
replace dG_cnews = 4 if dB_cnews_pubhealth == 1 // public heatlh
replace dG_cnews = 5 if dB_cnews_informal == 1 // informal
label var dG_cnews "categorical-Source relies most on for news about coronavirus outbreak"

label define dG_cnews ///
	1 "1_Intl/Natl" ///
	2 "2_Local news" ///
	3 "3_Politicians" ///
	4 "4_Pub Health" ///
	5 "5_Informal"
		
label val dG_cnews dG_cnews


***-----------------------------***
// COVIDFOL = HOW CLOSELY FOLLOW NEWS ABOUT COVID
***-----------------------------***

*How closely have you been following news about the outbreak of the coronavirus strain known as COVID-19?
	// 1 Very closely
	// 2 Fairly closely
	// 3 Not too closely
	// 4 Not at all closely
	
tab covidfol_w68, m
tab covidfol_w68, m nolabel

label define dG_newsfol ///
	 1 "Very closely" ///
	 2 "Fairly closely" ///
	 3 "Not too / at all closely"
	 
gen dG_newsfol = .
	replace dG_newsfol = 1 if covidfol_w68 == 1
	replace dG_newsfol = 2 if covidfol_w68 == 2
	replace dG_newsfol = 3 if covidfol_w68 == 3 | covidfol_w68 == 4
label val dG_newsfol dG_newsfol
label var dG_newsfol "How closely following news about COVID-19?"


gen dB_newsfol_vc = 0
	replace dB_newsfol_vc = 1 	if covidfol_w68  == 1
	replace dB_newsfol_vc = .n 	if covidfol_w68  == 99
label var dB_newsfol_vc "Very Closely - How closely following news about COVID-19?"
	
gen dB_newsfol_fc = 0
	replace dB_newsfol_fc = 1 	if covidfol_w68  == 2
	replace dB_newsfol_fc = .n 	if covidfol_w68  == 99
label var dB_newsfol_fc "Fairly Closely -  How closely following news about COVID-19?"

gen dB_newsfol_n = 0
	replace dB_newsfol_n = 1 	if covidfol_w68  == 3 |  covidfol_w68  == 4
	replace dB_newsfol_n = .n 	if covidfol_w68  == 99
label var dB_newsfol_n "Not too / at all closely - How closely following news about COVID-19?"

***-----------------------------***
// COVIDNEWSCHNG
***-----------------------------***

*local covidnewschng_c_w68
	*1Finding it HARDER to understand what is happening with the outbreak
	*2 Finding it EASIER to understand what is happening with the outbreak
	*3 No change

*local covidnewschng_d_w68
	*1 Seeing MORE partisan viewpoints in the news about the outbreak
	*2 Seeing FEWER partisan viewpoints in the news about the outbreak
	*3 No change

*local covidnewschng_e_w68
	*1 Finding it HARDER to identify what is true and what is false about the outbreak
	*2 Finding it EASIER to identify what is true and what is false about the outbreak
	*3 No change

***-----------------------------***
// COVIDINFODIFF
***-----------------------------***

*When you get news and information about the coronavirus outbreak, do you generally find it… [RANDOMIZE]
	*1 Difficult to determine what is true and what is not
	*2 Easy to determine what is true and what is not

tab covidinfodiff, m
tab covidinfodiff, m nolabel

gen dB_cinfodiff = .
replace dB_cinfodiff = 1 if covidinfodiff == 2
replace dB_cinfodiff = 0 if covidinfodiff == 1
label var dB_cinfodiff "When get news about COVID, difficult to determine what is true"

***-----------------------------***
// SAVE DATA	
***-----------------------------***

label data "`dataset' Knowledge variables"
notes: ckn`category'`dataset'.dta \ `dataset' with recoded knowledge variables \ ckn`category'`dataset'.do mmk $$_DATE
compress
datasignature set, reset
save $deriv/ckn`category'`dataset'.dta, replace

***--------------------------***

log close ckn`category'`dataset'
exit
