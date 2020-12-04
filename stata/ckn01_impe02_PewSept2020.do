local dataset `"02_PewSept2020"'
local category `"01_impe"'
cd $impe // import directory

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:     	Import "Pathways Sep 2020 (ATP W73).sav" and save to Derived folder
/*  data:    */ di "`dataset'"

//  github:   	covid_knowledge_news
//  OSF:		

//  author:   	Molly King

display "$S_DATE  $S_TIME"

***--------------------------***
// # PROGRAM SETUP
***-----------------------------***

version 16 // keeps program consistent for future replications
set linesize 80
clear all
set more off

***-----------------------------***
// # IMPORT
***-----------------------------***

cd $source/
import spss using "Pathways Sep 2020 (ATP W73).sav", case(lower)


***--------------------------***
// # WEIGHTING
***-----------------------------***

// Pew uses probability sampling: http://www.pewresearch.org/methodology/u-s-survey-research/sampling/
svyset _n [pweight=weight]

***--------------------------***
// # SAVE DATA
***-----------------------------***

label data "`dataset' data with weights: Pathways Sep 2020 (ATP W73)"
notes: ckn`category'`dataset'.dta \ Pathways Sep 2020 (ATP W73) with probability weights\ ckn`category'`dataset'.do mmk $S_DATE
compress
datasignature set

save $deriv/ki`category'`dataset'.dta, replace

***--------------------------***

log close ckn`category'`dataset'
exit
