local dataset `"01_PewJune2020"'
local category `"03_know"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***-----------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:     	Create Knowledge Variables - June Knowledge Questions
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

use $deriv/ckn02_demg`dataset'.dta, clear
save $deriv/ckn`category'`dataset'.dta, replace // data that results at end

***-----------------------------***

*variable labels
include $stata/ckn03_know00_include_variableLabels.doi

local refused_code = 99 // refused
local notascer_code none

***--------------------------***
// KNOWLEDGE VARIABLE CREATION
***-----------------------------***


// COVIDSTYHM
*As far as you know, how did states in the U.S. respond during the coronavirus outbreak?
local var_repl covidstyhm_w68
local new_var stateresponse

tab `var_repl', m
tab `var_repl', m nolab

local dk_code = 3 // don't know
local var_type ICDR

include $stata/ckn03_know00_include_IC.doi
label var `new_var'_c "correct, including don't knows: How did states in the U.S. respond during the coronavirus outbreak?"
label var `new_var'_ac "correct, given attempted: How did states in the U.S. respond during the coronavirus outbreak?"
label var `new_var'_dk "Not sure -  how did states in the U.S. respond during the coronavirus outbreak?"


// COVIDUNEMPLOY
*Is the national unemployment rate as reported by the government currently
local var_repl  covidunemploy_w68
local new_var unemploy

tab `var_repl', m
tab `var_repl', m nolab

local dk_code = 9 // don't know
local var_type IICIIDR

include $stata/ckn03_know00_include_IC.doi
label var `new_var'_c "correct, including don't knows: National unemployment rate as reported by the government currently around 15%"
label var `new_var'_ac "correct, given attempted: National unemployment rate as reported by the government currently around 15%"
label var `new_var'_dk "Not sure -  national unemployment rate as reported by the government currently ~15%"


// COVIDANTIBODIES
*As far as you know, are antibody tests for the coronavirus (also known as serology tests) intended to detect…
local var_repl covidantibodies_w68
local new_var antibody

tab `var_repl', m
tab `var_repl', m nolab

local dk_code = 3 // don't know
local var_type ICDR

include $stata/ckn03_know00_include_IC.doi
label var `new_var'_c "correct, including don't knows: Antibody tests detect previous coronavirus infections"
label var `new_var'_ac "correct, given attempted: Antibody tests detect previous coronavirus infections"
label var `new_var'_dk "Not sure - Antibody tests detect previous coronavirus infections"


// KNOWFAUCI 
*Do you happen to know who Anthony Fauci is? 
*correct = 3
local var_repl knowfauci_w68
local new_var fauci

tab `var_repl', m
tab `var_repl', m nolab

local dk_code = 5 // don't know
local var_type IICIDR

include $stata/ckn03_know00_include_IC.doi
label var `new_var'_c "correct, including don't knows: Anthony Fauci is an infectious disease expert & govt. adviser"
label var `new_var'_ac "correct, given attempted: Anthony Fauci is an infectious disease expert & govt. adviser"
label var `new_var'_dk "Not sure - Anthony Fauci is an infectious disease expert & govt. adviser"

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
