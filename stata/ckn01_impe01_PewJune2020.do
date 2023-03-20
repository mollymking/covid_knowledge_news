local dataset `"01_PewJune2020"'
local category `"01_impe"'
cd $impe // import directory

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:     	Import "Pathways June 2020 (ATP W68).sav" and save to Derived folder
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

***-----------------------------***
// # IMPORT
***-----------------------------***

cd $source/
import spss using "ATP W68.sav", case(lower)
*import spss using "Pathways June 2020 (ATP W68).sav", case(lower)

***--------------------------***
// # WEIGHTING
***-----------------------------***

// Pew uses probability sampling: http://www.pewresearch.org/methodology/u-s-survey-research/sampling/
svyset _n [pweight=weight_w68]

***--------------------------***
// # SAVE DATA
***-----------------------------***

label data "`dataset' data with weights: Pathways June 2020 (ATP W68)"
notes: ckn`category'`dataset'.dta \ Pew Pathways June 2020 (ATP W68) with probability weights\ ckn`category'`dataset'.do mmk $S_DATE
compress
datasignature set

save $deriv/ckn`category'`dataset'.dta, replace

***--------------------------***

log close ckn`category'`dataset'
exit
