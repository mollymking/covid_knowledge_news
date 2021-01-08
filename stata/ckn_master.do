cd "~/Documents/SocResearch/COVID_Knowledge_News/covid_knowledge_news/"

capture log close master
log using stata/ckn_master.log, name(master) replace text

** COVID_Knowledge_News - Master Data Management Do File ***

//	project:	COVID Knowledge & News

//  task:		Master file to rerun sequence of do-files to reproduce all work
//				related to data import, cleaning, and variable creation
//				This will run all files in stata folders

//  program:	ckn_master.do
//	log:      	ckn_master.log

//  github:		covid_knowledge_news
//  OSF:		https://osf.io/qf624/

//  author:		Molly King


// # PROGRAM SETUP
version 16 // keeps program consistent for future replications
set linesize 80
clear all
set more off

display "$S_DATE  $S_TIME"
***--------------------------***

*do file folders 

*Data
global source	"~/Documents/SocResearch/COVID_Knowledge_News/data/data_sorc"  	// original datasets
global deriv	"~/Documents/SocResearch/COVID_Knowledge_News/data/data_derv"  	// derived datasets

*Code
global stata  	"~/Documents/SocResearch/COVID_Knowledge_News/covid_knowledge_news/stata"

*Documentation
global docs 	"~/Documents/SocResearch/COVID_Knowledge_News/documentation"	// documentation folder

global results	"~/Documents/SocResearch/COVID_Knowledge_News/covid_knowledge_news/stata/results"  // tables and figures added to stata folder

/*
***--------------------------***
// 01 IMPORT AND EXTRACTION 
***--------------------------***

do $stata/ckn01_impe01_PewJune2020.do 				// Import "Pathways June 2020 (ATP W68).sav"
do $stata/ckn01_impe02_PewSept2020.do 				// Import "Pathways Sep 2020 (ATP W73).sav"
do $stata/ckn01_impe03_asec.do						// Import CPS ASEC 2019-2020 data

***--------------------------***
// 02 DEMOGRAPHIC VARIABLE CREATION 
***--------------------------***

do $stata/ckn02_demg01_PewJune2020.do 
do $stata/ckn02_demg02_PewSept2020.do

*Include files needed for above	
	*ckn02_demg00_education.doi
	*ckn02_demg00_include_female_from2W_1M.doi
	*ckn02_demg00_racethnicity.doi	

***--------------------------***
// 03 KNOWLEDGE VARIABLE CREATION (ckn03_know)
***--------------------------***

do $stata/ckn03_know01_PewJune2020.do
do $stata/ckn03_know02_PewSept2020.do

***--------------------------***
// 04 INCOME VARIABLES (ckn04_inc)  
*(Code income for all datasets using distribution data)
***--------------------------***

do $stata/ckn04_inc01_PewJune2020.do

***--------------------------***
// 05 NEWS VARIABLES (ckn04_news)  
***--------------------------***

do $stata/ckn05_news01_PewJune2020.do

***--------------------------***
// 06 DESCRIPTIVES
***--------------------------***

do $stata/ckn06_desc01_PewJune2020.do

***--------------------------***
// 07 REGRESSION
***--------------------------***

do $stata/ckn07_regr01_PewJune2020.do



***--------------------------***
log close master
exit
