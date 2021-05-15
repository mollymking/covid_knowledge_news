local dataset `"01_PewJune2020"'
local category `"04_inc"'

capture log close ckn`category'`dataset'
log using $stata/ckn`category'`dataset'.log, name(ckn`category'`dataset') replace text
***--------------------------***

// 	project:	Knowledge of COVID & News Sources
//  task:     	Income variables
//  data:     	di "`dataset'"

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

use $deriv/ckn03_know`dataset'.dta, clear
save $deriv/ckn`category'`dataset'.dta, replace // data that results at end

***-----------------------------***
// # COMBINE INCOME CATEGORIES FOR ONE BIG CATEGORY VARIABLE
***-----------------------------***

// USE OLD INCOME VARIABLE LABEL TO CREATE NEW VARIABLE LABEL
*label list
codebook f_income
*income uses value label X
uselabel labels82, clear // takes label and converts it into data table
// then can copy this and use it for creating new more robust data label for new variables

use $deriv/ckn`category'`dataset'.dta, clear

label define inc_categories_`dataset' ///
	1	"Less than 10,000" ///
	2	"10,000 to less than 20,000" ///
	3	"20,000 to less than 30,000" ///
	4	"30,000 to less than 40,000" ///
	5	"40,000 to less than 50,000" ///
	6	"50,000 to less than 75,000" ///
	7	"75,000 to less than 100,000" ///
	8	"100,000 to less than 150,000" ///
	9	"150,000 or more" ///
	99	"Refused" 


***-----------------------------***
// CREATE FAMILY INCOME VARIABLE

local family_income_variable f_income

tab `family_income_variable', m
tab `family_income_variable', m nolab

clonevar dL_finc = `family_income_variable'

*check if coded correctly
tab dL_finc `family_income_variable', m
tab dL_finc `family_income_variable', m

recode dL_finc 99 = .n //	Don't Know/refused

label var dL_finc "family Income"
lab val dL_finc inc_categories_`dataset'
notes dL_finc:`dataset' Family Income Categories from `family_income_variable' \ ckn`category'`dataset'.do mmk $S_DATE


***-----------------------------***
// CREATE FAMILY INCOME VARIABLE - LARGER CATEGORIES

tab dL_finc f_income_recode, m

label define inc_categories_broader ///
	1	"Less than 30,000" ///
	2	"30,000 to to less than 50,000" ///
	3	"50,000 to less than 75,000" ///
	4	"75,000 to less than 100,000" ///
	5	"100,000 to less than 150,000" ///
	6	"150,000 or more" ///
	.n	"Refused" 

gen		dG_finc = .
replace dG_finc = 1 if dL_finc == 1 | dL_finc == 2 | dL_finc == 3
replace dG_finc = 2 if dL_finc == 4 | dL_finc == 5
replace dG_finc = 3 if dL_finc == 6
replace dG_finc = 4 if dL_finc == 7
replace dG_finc = 5 if dL_finc == 8
replace dG_finc = 6 if dL_finc == 9
replace dG_finc = .n if dL_finc == .n


label var dG_finc "family Income - categories more than 1000 respondents"
lab val dG_finc inc_categories_broader
notes dG_finc:`dataset' Family Income Categories from `family_income_variable' \ ckn`category'`dataset'.do mmk $S_DATE

tab f_income dG_finc, m

// Binary Income Categories

local inc_var dG_finc
tab `inc_var', m nolab

*refused code(s) for `inc_var'
local inc_missing_condition `"`inc_var' == .n"' //Refused

local incl30k_condition 	`"`inc_var' == 1"' //	
local inc30_50k_condition 	`"`inc_var' == 2"' //	
local inc50_75k_condition 	`"`inc_var' == 3"'	// 
local inc75_100k_condition 	`"`inc_var' == 4"'	// 
local inc100_150k_condition `"`inc_var' == 5"'	// 
local inc150kp_condition 	`"`inc_var' == 6"'	// 

local inclist "l30k 30_50k 50_75k 75_100k 100_150k 150kp"
foreach inc of local inclist {
	gen dB_inc_`inc' = 0
	// Replace each with . for missing 
		if "`inc_missing_condition'" != "none" {
			replace dB_inc_`inc' = . if `inc_missing_condition'
		}
	label var dB_inc_`inc' "Inc category `inc'"
	label define dB_inc_`inc' 0 "Not `inc'" 1 "`inc'"
		label val dB_inc_`inc' dB_inc_`inc'
	notes dB_inc_`inc': Income category `inc'. created from `inc_var' variable in `dataset' \ ckn`category'`dataset'.do mmk $S_DATE

	replace dB_inc_`inc' = 1 if `inc`inc'_condition'
}

tab `inc_var' dG_finc, m
tab `inc_var' dB_inc_l30k, m
tab `inc_var' dB_inc_75_100k, m


// SAVE
save $deriv/ckn`category'`dataset'.dta, replace 

***-----------------------------***
// # FAMILY INCOME - CONTINUOUS
***-----------------------------***
/*
local inc_var `"dL_finc"' //Specify which variable using as income variable
local inc_type "family" 
local year "year"

// A) ASEC CONTINUOUS INCOME CONVERSIONS

*! Convert categorical to continuous income values, independent of values of categories
*! creates numeric variables indicating edges of income categories,
*! and draws random continuous income from CPS-ASEC from between those edges
*! several locals must be specified before running this:

	// `inc_type' specifies either family, family, or personal as income types
	// `inc_var' is the name of the categorical income variable in the original dataset
	// `year' is the name of the year variable (any form of time is fine, as long as it's numeric)


// #1 SETUP
	noisily
	set seed 1
	compress
	version 13
	
	//Create local for levels of income = e.g., levelsof year, local(years)
	levelsof `inc_var', local(`"`inc_var'_levels"')

	//Create variable will need to store income level
	gen `inc_var'_cat = " "

	// sort for later join & create variable recording the original observation order within the identifier
	bysort `year' `inc_var': gen year_inc_id = _n

// #2 create numeric variables indicating edges of income categories //
	// Note: for more detail on if-command and Stata regular expressions used to create this, see:
		*http://www.stata.com/statalist/archive/2013-03/msg00654.html
		*http://www.stata.com/support/faqs/programming/if-command-versus-if-qualifier/
		*http://stats.idre.ucla.edu/stata/faq/how-can-i-extract-a-portion-of-a-string-variable-using-regular-expressions/

	// List income levels
	di "The income levels are: " "``inc_var'_levels'"

	* DECODE to CONVERT LABELS TO STRING VARIABLES
	decode `inc_var', gen(inc_decoded)
	*describe inc_decoded

	tempfile working_regex
	save `working_regex', replace

	// loop through all values of income categories (`inc_level') in `dataset'
	foreach inc_level of local `inc_var'_levels {

		use `working_regex', clear

		// Keep the data if the income variable is equal to the current income level (of the loop)
		keep if `inc_var' == `inc_level'  // do this to make sure not replacing things with wrong inc_var_cat later
			di "The current inc_level is: " `inc_level'

			// Make sure working with proper income label text in `inc_var'_cat
			replace `inc_var'_cat = inc_decoded

			// text at beginning of the string:
				if regexm(`inc_var'_cat, "^[a-z/A-Z]+") == 1 {
					di "The inc_level " `inc_level' " is at the lowest end of the income range"
					// for lower-bound values, will match if text at beginning of line
					destring `inc_var'_cat, ignore("Less than LESS THAN Under,$ ") generate(`inc_var'_ub) // parses out these words
					gen `inc_var'_lb = 0
				}

			// text at end of the string:
				else if regexm(`inc_var'_cat, "[a-z/A-Z]+$") == 1 {
					di "The inc_level " `inc_level' " is at the highest end of the income range"
					// for upper-bound values, will match if text at end of line
					destring `inc_var'_cat, ignore("and over or over,$ or more OR MORE") generate(`inc_var'_lb) // parses out these words
					gen `inc_var'_ub = 999999  // my topcode for asec purposes
				}

			// if `inc_var'_cat is missing, keep it missing for lower_bound and upper_bound
				else if regexm(`inc_var'_cat, "[.][a-z]") == 1 {
					di "The inc_level " `inc_level' " is all missing"
				 // for missing values (a bit excessive, since already missing, but good to be sure)
					gen `inc_var'_lb = .
					gen `inc_var'_ub = .
				}

			// for labels with 2 numbers in them
				else if regexm(`inc_var'_cat, "[0-9]+$") == 1 {
				// regex "[0-9]+$" will match anything of form $0000 or 0000 at end of line -
				// since those at lowest and highest ranges have already been matched (using text), this leaves those with ranges
						di "The inc_level " `inc_level' " has a lower and an upper level"
						split `inc_var'_cat, ///
							parse("-" "to" "-" "to under" "to less than" "UP TO" "but less than") ///
							ignore(" "$,) destring
						gen `inc_var'_lb = `inc_var'_cat1
						gen `inc_var'_ub = `inc_var'_cat2
				}

			// error - in case doesn't fit any existing category
				else {
					di "The inc_level " `inc_level' " does not fit any of the existing regular expressions designs."
				}

			// Save these new data - include numerical income upper and lower bounds in tempfile for later for merging, etc.
				tempfile temp_`inc_level'
				save `temp_`inc_level'', replace

			// create locals to use later for selecting appropriate ASEC bounds
				local upper_bound = `inc_var'_ub
				local lower_bound = `inc_var'_lb


			// #3 Now, still within the single-income-level loop in original dataset, loop through each year in the dataset:

				//Levels of year variable to loop through years in dataset
					levelsof `year', local(years)
					di "Create local variable years to loop through within that income bracket - values:" `years'

				foreach y of local years { // loop through all years in `dataset'

					use `temp_`inc_level'', clear

					// summarize so can get count of how many individuals in that income level during year (in dataset)
					quietly summarize if `year' == `y' & `inc_var' == `inc_level'
					local sample_size = r(N) // count how many rows there are in survey dataset

					// create temporary file of just this income level and year can merge ASEC incomes back into later
					keep if `year' == `y' & `inc_var' == `inc_level'
					tempfile premerge_`inc_level'_`y'
					save `premerge_`inc_level'_`y'', replace

					// #3A) Selects appropriate ASEC dataset (of a certain type, either fam, hh, or pers) //

					if "`inc_type'" == "family" {
						use $deriv/ckn01_impe03_asec.dta, clear // use ASEC family dataset
						local asec_inc_var "ftotval" // name in ASEC dataset
						local final_inc_var "dV_finc"
						di "Calculating family income using ftotval ASEC variable."
					}
					else if "`inc_type'" == "family" {
						use $deriv/ckn01_impe03_asec.dta, clear // use ASEC family dataset
						local asec_inc_var "hhincome" // name in ASEC dataset
						local final_inc_var "dV_hinc"
						di "Calculating family income using hhincome ASEC variable."
					}
					else if "`inc_type'" == "personal" {
						use $deriv/ckn01_impe03_asec.dta, clear // use ASEC individual-weighted dataset
						local asec_inc_var "inctot" // name in ASEC dataset
						local final_inc_var "dV_rinc"
						di "Calculating personal income using inctot ASEC variable."
					}
					else {
						display as error "Income types allowed: family, family, or personal."
					}

					// #3B) Takes a random draw of number of incomes w/in that income boundary and year from the CPS-ASEC

						// Keep ASEC data if within income bounds and for given year

						keep if `year' == `y' & ///
							`asec_inc_var' >= `lower_bound' & ///
							`asec_inc_var' <= `upper_bound'
						di "Calculating income between $`lower_bound' and $`upper_bound' for `y' year."

						sample `sample_size', count
							// keeps sample_size (N) of ASEC sample
							// Note: svy: NOT SUPPORTED FOR SAMPLE
						di "Sampling N=`sample_size' incomes from ASEC `asec_inc_var' dataset at `inc_level' ($`lower_bound'-`upper_bound') level and year `y'."

						// Add new columns for lower_bound and upper_bound using locals created from values above
						// these will be used to merge ASEC data back into original dataset
						gen `inc_var'_lb = `lower_bound'
						gen `inc_var'_ub = `upper_bound'

						// Also save case id for merging later
						gen year_inc_id = _n

						// Income values are assigned to rows within the income category in the temp survey dataset
						quietly merge 1:1 `year' `inc_var'_lb `inc_var'_ub year_inc_id using `premerge_`inc_level'_`y''
						di "Merged ASEC values with original dataset for inc_level " `inc_level' " ($`lower_bound'-`upper_bound') and year `y'."


						// Save these new data with yearly ASEC continuous data in a tempfile we can use later for merging, etc.
						tempfile `inc_level'_`y'
						save ``inc_level'_`y'', replace
						di "Saved ASEC continuous data for inc_level " `inc_level' " ($`lower_bound'-`upper_bound') and year `y' in file "

				}	// end of loop through all years of `dataset' dataset

			di "Moved outside loop of years for income bracket" `inc_level' " ($`lower_bound'-`upper_bound')."

		// append all years within one income bracket
			tokenize `years'
			local first `1'
			use ``inc_level'_`1'', clear
			macro shift
			local rest `*'

		// now loop through and append each yearly temp file created earlier
			foreach data in `*' {
				append using ``inc_level'_`data''
			}
			di "Appended all years within income bracket " `inc_level' " ($`lower_bound'-`upper_bound')."

		// create new tempfile to save all years data for a given income level
			tempfile temp_`inc_level'_allyrs
			save `temp_`inc_level'_allyrs', replace
			di "Saved new tempfile temp_`inc_level'_allyrs with all years for income bracket" `inc_level' " ($`lower_bound'-`upper_bound')."


	} //  end of loop through all income brackets of `dataset' dataset

// append all continuous incomes
// now bring together all files created in above loop as tempfiles
	tokenize ``inc_var'_levels'
	local first `1'
	use `temp_`1'_allyrs', clear
	macro shift
	local rest `*'

// now loop through and append each temp file created within income bracket loop
	foreach data in `*' {
		append using `temp_`data'_allyrs'
	}


// CLEAN UP

// drop variables used in creating lower and upper bounds - no longer necessary, possibly confusing
	drop `inc_var'_cat1
	drop `inc_var'_cat2
	drop  inc_decoded

// Label new upper and lower income bound variables
	label variable `inc_var'_lb "`inc_var' Lower Bound"
	label variable `inc_var'_ub "`inc_var' Upper Bound"

// Label new continuous income variable
	rename `asec_inc_var' `final_inc_var'
		label var `final_inc_var' "`dataset' continuous `inc_type' income"

sort `year' `inc_var' year_inc_id
drop  year_inc_id

drop _merge

***-----------***

// C) CREATE NATURAL LOG INCOME VARIABLES

gen dV_finc_1k = dV_finc / 1000

gen dV_finc_ln = ln(dV_finc)
gen dV_finc_ln_1k = ln(dV_finc_1k)

replace dV_finc_ln = 0 if dV_finc == 0
replace dV_finc_ln_1k = 0 if dV_finc == 0


***-----------------------------***
//  CLEANUP
***-----------------------------***

* Drop any years not in dataset, so get rid of extra years merged in
drop if year != 2019

*Drop ASEC variables
drop serial month cpsid asecflag mish hhincome hrhhid hrhhid2 pernum cpsidp asecwt age lfproxy inctot 

order f_income dL_finc dV_finc dV_finc_1k dV_finc_ln dV_finc_ln_1k

***-----------------------------***
//  SAVE OVERALL DATASET
***-----------------------------***

label data "`dataset' data with continuous family income measures"
notes: ckn`category'`dataset' \ `dataset' with continuous family incomes  \ ckn`category'`dataset'.do mmk $S_DATE
compress
datasignature set, reset

save $deriv/ckn`category'`dataset', replace

***-----------------------------***
*/

log close ckn`category'`dataset'
exit
