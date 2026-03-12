// Disable variable abbreviation for clarity
set varabbrev off 

// Define a global variable for the data directory path
global data = "/Users/sayedkhan/Desktop/Thesis/Data"

// Import the first dataset, drop duplicate rows based on shrid2, and process it
import delimited "/Users/sayedkhan/Desktop/Thesis/Data/Intersection_5km.csv", clear
duplicates drop shrid2, force
gen treat = 1 // Create a variable indicating treatment group
rename name name_treat // Rename the 'name' variable for clarity
save "$data/Intersection_5km.dta" // Save processed data

// Import the second dataset, drop duplicates, and process it
import delimited "/Users/sayedkhan/Desktop/Thesis/Data/Intersection_10km_wedge.csv", clear
duplicates drop shrid2, force
gen control = 1 // Create a variable indicating control group
rename name name_control // Rename the 'name' variable for clarity
save "$data/Intersection_10km.dta"// Save processed data

// Load the main dataset and clean it
use "$data/Dam_all_data.dta", clear
drop if missing(name) // Remove observations with missing 'name'
save "$data/Dam_all_data.dta"// Save the cleaned dataset

// Load another dataset for variable renaming and reshaping
use "$data/basin with merged data.dta", clear

// Rename variables starting with 'ec' to include year suffix
foreach var of varlist ec* {
    local year = substr("`var'", 3, 2) // Extract year from variable name
    local newname = substr("`var'", 6, .) + "_" + string(`year') // Construct new name
    rename `var' `newname' // Rename the variable
}

// Reshape the data from wide to long format for analysis
reshape long emp_shric_901_ emp_shric_891_ emp_shric_881_ emp_shric_871_ emp_shric_861_ emp_shric_851_ emp_shric_841_ emp_shric_831_ emp_shric_821_ emp_shric_811_ emp_shric_801_ emp_shric_791_ emp_shric_781_ emp_shric_771_ emp_shric_761_ emp_shric_751_ emp_shric_741_ emp_shric_731_ emp_shric_721_ emp_shric_711_ emp_shric_701_ emp_shric_691_ emp_shric_681_ emp_shric_671_ emp_shric_661_ emp_shric_651_ emp_shric_641_ emp_shric_631_ emp_shric_621_ emp_shric_611_ emp_shric_601_ emp_shric_591_ emp_shric_581_ emp_shric_571_ emp_shric_561_ emp_shric_551_ emp_shric_541_ emp_shric_531_ emp_shric_521_ emp_shric_511_ emp_shric_501_ emp_shric_491_ emp_shric_481_ emp_shric_471_ emp_shric_461_ emp_shric_451_ emp_shric_441_ emp_shric_431_ emp_shric_421_ emp_shric_411_ emp_shric_401_ emp_shric_391_ emp_shric_381_ emp_shric_371_ emp_shric_361_ emp_shric_351_ emp_shric_341_ emp_shric_331_ emp_shric_321_ emp_shric_311_ emp_shric_301_ emp_shric_291_ emp_shric_281_ emp_shric_271_ emp_shric_261_ emp_shric_251_ emp_shric_241_ emp_shric_231_ emp_shric_221_ emp_shric_211_ emp_shric_201_ emp_shric_191_ emp_shric_181_ emp_shric_171_ emp_shric_161_ emp_shric_151_ emp_shric_141_ emp_shric_131_ emp_shric_121_ emp_shric_111_ emp_shric_101_ emp_shric_91_ emp_shric_81_ emp_shric_71_ emp_shric_61_ emp_shric_51_ emp_shric_41_ emp_shric_31_ emp_shric_21_ emp_shric_11_ emp_services_ emp_manuf_ count_other_ count_obc_ count_sc_ count_st_ count_size101_ count_size100_ count_size50_ count_size20_ count_pub_mines_ count_pub_banks_ count_own_other_ count_own_f_ count_own_m_ count_priv_ count_gov_ count_m_ count_f_ count_all_ emp_other_ emp_obc_ emp_sc_ emp_st_ emp_size101_ emp_size100_ emp_size50_ emp_size20_ emp_pub_mines_ emp_pub_banks_ emp_own_other_ emp_own_f_ emp_own_m_ emp_priv_ emp_gov_ emp_unhired_f_ emp_unhired_m_ emp_unhired_ emp_hired_f_ emp_hired_m_ emp_hired_ emp_m_ emp_f_ emp_all_, i(shrid2) j(census_year)
keep if basin==1
save "$data/reshape_data.dta" // Save the reshaped dataset

// Merge datasets to include treatment and control information
use "$data/reshape_data.dta", clear
merge m:1 shrid2 using "$data/Intersection_10km.dta", nogen keep(match master) keepusing(name_control control)
merge m:1 shrid2 using "$data/Intersection_5km.dta", nogen keep(match master) keepusing(name_treat treat)
gen name = name_control 
replace name = name_treat if !missing(name_treat)

 

// Merge with main dataset for dam information
merge m:1 name using "$data/Dam_all_data.dta", nogen keep(match master) keepusing(projectname lengthm maxheightabovefoundationm completionyear type)
save "$data/reshape_merged_dam_all_data.dta" // Save the combined file dam data and basin data
use "$data/reshape_merged_dam_all_data.dta",clear
// Standardize census_year values for consistency
replace census_year = 1990 if census_year == 90
replace census_year = 1998 if census_year == 98
replace census_year = 2005 if census_year == 5
replace census_year = 2013 if census_year == 13

// Create a variable for dam proximity and its status
gen near_dam = .
replace near_dam = 0 if control == 1 &treat==.
replace near_dam = 1 if treat == 1 
tab near_dam // Check distribution of near_dam

**************************         **************************
************************** ****    **************************
**************************         **************************

// Create a variable indicating whether the dam was completed 
gen complete = .
replace complete = 0 if census_year < completionyear & !missing(near_dam)
replace complete = 1 if census_year >= completionyear & !missing(near_dam)

// Analyze firm density (count_all_) and other metrics over time by dam proximity
table census_year near_dam, c(sum count_all_)
lgraph count_all_ census_year, s(sum) by(near_dam)

// Analyze employment in services and manufacturing by dam proximity
table census_year near_dam, c(sum emp_services_)
lgraph emp_services_ census_year, s(sum) by(near_dam)
table census_year near_dam, c(sum emp_manuf_)
lgraph emp_manuf_ census_year, s(sum) by(near_dam)

egen count_adjusted = mean(count_all_)

**************************         **************************
************************** ****    **************************
**************************         **************************




****gen event= census_year-completionyear

****8gen post1 = 1 if inrange(event,0,7)
****8replace post1 = 0 if event<=1





// Generate average employment dynamically using the original data
egen avg_employment = sum(count_all_), by(census_year treatment)
replace avg_employment=avg_employment/78.5 if inlist(treatment,1,2)
replace avg_employment=avg_employment/235.5 if treatment==0

egen avg_emp_ = sum(count_all_), by(census_year treatment)
****Graphs***


twoway (line avg_employment census_year if treatment == 0, sort lcolor(red))(line avg_employment census_year if treatment == 1, sort lcolor(blue))(line avg_employment census_year if treatment == 2, sort lcolor(green))(line avg_employment census_year if treatment == 3, sort lcolor(black))           ///
   
***lgraph avg_employment event, by(treatment)
lgraph avg_employment census_year, by(treatment)
lgraph avg_emp_ census_year, by(treatment)


lgraph count_adjusted census_year, by(treatment)

************************************************************************************
***************************** Regression********************************************
************************************************************************************
//// use data from population census do file////////////////////////////////////////

gen post = .
replace post = 1 if inrange(completionyear,1998,2005)
replace post = 0 if inrange(completionyear,1982,1997)



gen adult_1990_population=.
replace adult_1990_population=adult_population if census_year==1990

gen adult_2001_population=.
gen adult_2001_population=adult_population if pop_census_year==2001


gen growth_rate_1 = .

bysort shrid2 (census_year): replace growth_rate_1 = (adult_2001_population - adult_1990_population)/10 if census_year == 1998


gen growth_rate_1 =(adult_2001_population - adult_1990_population)/10
 
 reg employment_adult_share near_dam##post 

reg cultivators_adult_share  near_dam##post
reg agri_labourers_adult_share  near_dam##post
reg marginal_workers_adult_share  near_dam##post

reg emp_services_adult_share   near_dam##post
reg emp_manufacturing_adult_share    near_dam##post



egen shrid2_code = group(shrid2)
xtset  shrid2_code pop_census_year
xtset shrid2_code pop_census_year

xtreg cultivators near_dam##post, fe

xtreg mean_emp near_dam##post,fe
xtreg mean_cultivators  near_dam##post, fe

reg employment_adult_share near_dam##post, robust cluster(shrid2_code) 
reg cultivators near_dam##post, robust cluster(shrid2_code) 


reghdfe employment_adult_share near_dam##post , absorb(subdistrict_name)

reg employment_adult_share near_dam##post, cluster(shrid2_code)

bysort shrid2_code (near_dam post): gen variation = near_dam[_n] != near_dam[_n-1] | post[_n] != post[_n-1]
tab variation

gen population=.
replace population=total_1990_population if census_year == 1990
replace population=total_1998_population if census_year == 1998
replace population=total_2005_population if census_year == 2005
replace population=total_2013_population if census_year == 2013



//// do file for exploring shrid with different level of treatment.
set varabbrev off 

// Define a global variable for the data directory path
global data = "/Users/sayedkhan/Desktop/Thesis/Data"

use "$data/ec_pop_census_5km_30km_earliestshrid.dta", clear
gen log_emp_all = log(emp_all_ + 1)
gen log_agri_labourers = log(agri_labourers+ 1)
gen log_cultivators = log(cultivators+ 1)
gen log_marginal_workers=log(marginal_workers+ 1)
gen log_firmcount = log(count_all_ + 1)
gen log_population =log(population+1)

gen post = .
replace post = 0 if completionyear > census_year & inrange(completionyear, 1999, 2005)
replace post = 1 if completionyear <= census_year & inrange(completionyear, 1999, 2005)
replace post = . if missing(completionyear) 


egen subdistrict_code = group(subdistrict_name)

xtset shrid2_code census_year

*********** Summary Table **********************************			
// **Population**
eststo pop_1: xtreg log_population ib4.near_dam##post, fe
eststo pop_2: reghdfe log_population ib4.near_dam##post, absorb(shrid2_code) cluster(name#near_dam)

// **Employment Change**
eststo emp_1: xtreg log_emp_all ib4.near_dam##post, fe
eststo emp_2: reghdfe log_emp_all ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

// **Cultivators**
eststo cult_1: xtreg log_cultivators ib4.near_dam##post, fe
eststo cult_2: reghdfe log_cultivators ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

// **Agricultural Labourers**
eststo agri_1: xtreg log_agri_labourers ib4.near_dam##post, fe
eststo agri_2: reghdfe log_agri_labourers ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

// **Marginal Workers**
eststo marg_1: xtreg log_marginal_workers ib4.near_dam##post, fe
eststo marg_2: reghdfe log_marginal_workers ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

// **Firm Count**
eststo firm_1: xtreg log_firmcount ib4.near_dam##post, fe
eststo firm_2: reghdfe log_firmcount ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)


// **Calculate P-values and Means**
test 1.near_dam#1.post = 2.near_dam#1.post
local pval_5_10 : di %6.3f r(p)

test 1.near_dam#1.post = 3.near_dam#1.post
local pval_5_20 : di %6.3f r(p)

// **Calculate Sample Means for Reference**
sum emp_all_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_emp_all : di %6.2f r(mean)

sum cultivators if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_cultivators : di %6.2f r(mean)

sum agri_labourers if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_agrilab : di %6.2f r(mean)

sum marginal_workers if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_marginal_w : di %6.2f r(mean)

sum count_all_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_firm_count : di %6.2f r(mean)

sum population if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_population : di %6.2f r(mean)

// **Export Combined Table to Word (.doc)**
esttab  pop_2 emp_2 cult_2 agri_2  marg_2 firm_2 using "$data/employed_individuals_30_.doc", replace ///
    nodepvar nopa nocon label nogaps nonum ///
    keep(1.near_dam#1.post 2.near_dam#1.post 3.near_dam#1.post) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Summary of Employed Individuals Differences Across Categories") ///
    mtitles( "Population" ///
	"Total Employment " ///
            "Cultivators" ///
            "Agri Labourers " ///
            "Marginal Workers " ///
            "Firm Count ") ///
      s(N r2, label("N" "R-squared")) ///
    varlabels(1.near_dam#1.post "0-5km" ///
              2.near_dam#1.post "5-10km" ///
              3.near_dam#1.post "10-20km") ///
			      se /// 
     note("Test: 0-5km vs 5-10km, p-value = `pval_5_10'. " ///
         "Test: 0-5km vs 10-20km, p-value = `pval_5_20'. " ///
		 "Reference mean (Population)20-30km = `mean_population'." ///
         "Reference mean (Employment)20-30km = `mean_emp_all'. " ///
         "Reference mean (Cultivators)20-30km = `mean_cultivators'. " ///
         "Reference mean (Agri Labourers)20-30km = `mean_agrilab'. " ///
         "Reference mean (Marginal Workers)20-30km = `mean_marginal_w'. " ///
         "Reference mean (Firm Count)20-30km = `mean_firm_count'." )
		 
		 
************ Regression Using Interaction Number of Years Since dam*************

gen event = .  
replace event = census_year - completionyear if inrange(completionyear, 1998, 2005)

***** Exporting Summary Employment with event ***********
// Population 
eststo pop_2: reghdfe log_population ib4.near_dam##post##c.event, absorb(shrid2_code) cluster(name#near_dam)

// **Employment Change**
eststo emp_2: reghdfe log_emp_all ib4.near_dam##post##c.event population, absorb(shrid2_code) cluster(name#near_dam)

// **Cultivators**
eststo cult_2: reghdfe log_cultivators ib4.near_dam##post##c.event population, absorb(shrid2_code) cluster(name#near_dam)

// **Agricultural Labourers**
eststo agri_2: reghdfe log_agri_labourers ib4.near_dam##post##c.event population, absorb(shrid2_code) cluster(name#near_dam)

// **Marginal Workers**
eststo marg_2: reghdfe log_marginal_workers ib4.near_dam##post##c.event population, absorb(shrid2_code) cluster(name#near_dam)

// **Firm Count**
eststo firm_2: reghdfe log_firmcount ib4.near_dam##post##c.event population, absorb(shrid2_code) cluster(name#near_dam)

// **Calculate P-values and Means**
test 1.near_dam#1.post = 2.near_dam#1.post
local pval_5_10 : di %6.3f r(p)
test 1.near_dam#1.post = 3.near_dam#1.post
local pval_5_20 : di %6.3f r(p)


// **Calculate Sample Means for Reference**
sum emp_all_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_emp_all : di %6.2f r(mean)

sum cultivators if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_cultivators : di %6.2f r(mean)

sum agri_labourers if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_agrilab : di %6.2f r(mean)

sum marginal_workers if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_marginal_w : di %6.2f r(mean)

sum count_all_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_firm_count : di %6.2f r(mean)

sum population if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_population : di %6.2f r(mean)

// **Export Combined Table to Word (.doc)**
esttab pop_2 emp_2 cult_2 agri_2 marg_2 firm_2 using "$data/employed_individuals_30_yeras.doc", replace ///
    nodepvar nopa nocon label nogaps nonum ///
    keep( 1.near_dam#1.post#c.event 2.near_dam#1.post#c.event 3.near_dam#1.post#c.event) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Summary of Employed Individuals Differences Across Categories") ///
    mtitles( "Population" ///
	"Total Employment " ///
            "Cultivators" ///
            "Agri Labourers " ///
            "Marginal Workers " ///
            "Firm Count ") ///
    s(N r2, label("N" "R-squared")) ///
    varlabels(1.near_dam#1.post#c.event "0-5km x Post × Years Since Dam" ///
			  2.near_dam#1.post#c.event "5-10km x Post × Years Since Dam" ///
			  3.near_dam#1.post#c.event "10-20km x Post x Years Since Dam")  ///
             se ///
   note("Test: 0-5km vs 5-10km, p-value = `pval_5_10'. " ///
         "Test: 0-5km vs 10-20km, p-value = `pval_5_20'. " ///
		 "Reference mean (Population)20-30km = `mean_population'." ///
         "Reference mean (Employment)20-30km = `mean_emp_all'. " ///
         "Reference mean (Cultivators)20-30km = `mean_cultivators'. " ///
         "Reference mean (Agri Labourers)20-30km = `mean_agrilab'. " ///
         "Reference mean (Marginal Workers)20-30km = `mean_marginal_w'. " ///
         "Reference mean (Firm Count)20-30km = `mean_firm_count'." )
		 
	
************************** Regression Using Interaction height*********************************
gen log_height = log(maxheightabovefoundationm) if !missing(post)


***** Exporting Summary Employment with event ***********

// Population
// **Employment Change**
eststo emp_2: reghdfe log_emp_all ib4.near_dam##post##c.log_height population, absorb(shrid2_code) cluster(name#near_dam)

// **Cultivators**
eststo cult_2: reghdfe log_cultivators ib4.near_dam##post##c.maxheightabovefoundationm population, absorb(shrid2_code) cluster(name#near_dam)

// **Agricultural Labourers**
eststo agri_2: reghdfe log_agri_labourers ib4.near_dam##post##c.maxheightabovefoundationm population, absorb(shrid2_code) cluster(name#near_dam)

// **Marginal Workers**
eststo marg_2: reghdfe log_marginal_workers ib4.near_dam##post##c.maxheightabovefoundationm population, absorb(shrid2_code) cluster(name#near_dam)

// **Firm Count**
eststo firm_2: reghdfe log_firmcount ib4.near_dam##post##c.maxheightabovefoundationm population, absorb(shrid2_code) cluster(name#near_dam)

// **Calculate P-values and Means**
test 1.near_dam#1.post = 2.near_dam#1.post
local pval_5_10 : di %6.3f r(p)
test 1.near_dam#1.post = 3.near_dam#1.post
local pval_5_20 : di %6.3f r(p)


// **Calculate Sample Means for Reference**
sum emp_all_ if e(sample) & near_dam == 4 & inrange(completionyear, 1998, 2005)
local mean_emp_all : di %6.2f r(mean)

sum cultivators if e(sample) & near_dam == 4 & inrange(completionyear, 1998, 2005)
local mean_cultivators : di %6.2f r(mean)

sum agri_labourers if e(sample) & near_dam == 4 & inrange(completionyear, 1998, 2005)
local mean_agrilab : di %6.2f r(mean)

sum marginal_workers if e(sample) & near_dam == 4 & inrange(completionyear, 1998, 2005)
local mean_marginal_w : di %6.2f r(mean)

sum count_all_ if e(sample) & near_dam == 4 & inrange(completionyear, 1998, 2005)
local mean_firm_count : di %6.2f r(mean)


// **Export Combined Table to Word (.doc)**
esttab emp_2 cult_2 agri_2 marg_2 firm_2 using "$data/employed_individuals_30_height.doc", replace ///
    nodepvar nopa nocon label nogaps nonum ///
    keep(1.near_dam#1.post#c.log_height 2.near_dam#1.post#c.log_height 3.near_dam#1.post#c.log_height 1.near_dam#1.post#c.maxheightabovefoundationm 2.near_dam#1.post#c.maxheightabovefoundationm 3.near_dam#1.post#c.maxheightabovefoundationm) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Summary of Employment Changes Across Categories") ///
    mtitles( "Total Employment " ///
            "Cultivators" ///
            "Agri Labourers " ///
            "Marginal Workers " ///
            "Firm Count ") ///
    s(N r2, label("N" "R-squared")) ///
    varlabels(1.near_dam#1.post#c.maxheightabovefoundationm "0-5km x Post x Height" ///
          2.near_dam#1.post#c.maxheightabovefoundationm "5-10km x Post x Height" ///
          3.near_dam#1.post#c.maxheightabovefoundationm "10-20km x Post x Height" ///
          1.near_dam#1.post#c.log_height "0-5km x Post x Height" ///
          2.near_dam#1.post#c.log_height "5-10km x Post x Height" ///
          3.near_dam#1.post#c.log_height "10-20km x Post x Height") ///
              se ///
   note("Test: 0-5km vs 5-10km, p-value = `pval_5_10'. " ///
         "Test: 0-5km vs 10-20km, p-value = `pval_5_20'. " ///
         "Reference mean (Employment)20-30km = `mean_emp_all'. " ///
         "Reference mean (Cultivators)20-30km = `mean_cultivators'. " ///
         "Reference mean (Agri Labourers)20-30km = `mean_agrilab'. " ///
         "Reference mean (Marginal Workers)20-30km = `mean_marginal_w'. " ///
         "Reference mean (Firm Count)20-30km = `mean_firm_count'." )
		 
		 
****************Regression using interaction Length of the dam **************************

gen log_length = log(lengthm) if !missing(post)
gen log_emp_manuf =log(emp_manuf_) if !missing(post)
gen log_emp_services = log(emp_services_) if !missing(post)

***** Exporting Summary Employment with event ***********

// Population
// **Employment Change**
eststo emp_2: reghdfe log_emp_all ib4.near_dam##post##c.lengthm population, absorb(shrid2_code) cluster(name#near_dam)

// **Cultivators**
eststo cult_2: reghdfe log_cultivators ib4.near_dam##post##c.lengthm population, absorb(shrid2_code) cluster(name#near_dam)


// **Calculate P-values and Means**
test 1.near_dam#1.post = 2.near_dam#1.post
local pval_5_10 : di %6.3f r(p)
test 1.near_dam#1.post = 3.near_dam#1.post
local pval_5_20 : di %6.3f r(p)


// **Calculate Sample Means for Reference**
sum emp_all_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_emp_all : di %6.2f r(mean)

sum cultivators if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_cultivators : di %6.2f r(mean)



// **Export Combined Table to Word (.doc)**
esttab emp_2 cult_2 using "$data/employed_individuals_30_length.doc", replace ///
    nodepvar nopa nocon label nogaps nonum ///
    keep(1.near_dam#1.post#c.lengthm 2.near_dam#1.post#c.lengthm 3.near_dam#1.post#c.lengthm) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Summary of Employment Changes Across Categories") ///
    mtitles( "Total Employment " ///
            "Cultivators") ///
            s(N r2, label("N" "R-squared")) ///
    varlabels(1.near_dam#1.post#c.lengthm "0-5km x Post x Length" ///
              2.near_dam#1.post#c.lengthm "5-10km x Post x Length" ///
              3.near_dam#1.post#c.lengthm "10-20km x Post x Length") ///
              se ///
   note("Test: 0-5km vs 5-10km, p-value = `pval_5_10'. " ///
         "Test: 0-5km vs 10-20km, p-value = `pval_5_20'. " ///
         "Reference mean (Employment)20-30km = `mean_emp_all'. " ///
         "Reference mean (Cultivators)20-30km = `mean_cultivators'. ") ///
         
		 
*************** Regression Sector wise*****************



*********** Summary Table **********************************			
// **Population**
eststo pop_1: xtreg log_population ib4.near_dam##post, fe
eststo pop_2: reghdfe log_population ib4.near_dam##post, absorb(shrid2_code) cluster(name#near_dam)

// **Employment Change**
eststo emp_1: xtreg log_emp_all ib4.near_dam##post, fe
eststo emp_2: reghdfe log_emp_all ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)
 /// Manufacturing
eststo emp_1_m: xtreg log_emp_manuf ib4.near_dam##post, fe
eststo emp_2_m: reghdfe log_emp_manuf ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

//Services
eststo emp_1_s: xtreg log_emp_services ib4.near_dam##post, fe
eststo emp_2_s: reghdfe log_emp_services ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)


// **Cultivators**
eststo cult_1: xtreg log_cultivators ib4.near_dam##post, fe
eststo cult_2: reghdfe log_cultivators ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

// **Agricultural Labourers**
eststo agri_1: xtreg log_agri_labourers ib4.near_dam##post, fe
eststo agri_2: reghdfe log_agri_labourers ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

// **Marginal Workers**
eststo marg_1: xtreg log_marginal_workers ib4.near_dam##post, fe
eststo marg_2: reghdfe log_marginal_workers ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

// **Firm Count**
eststo firm_1: xtreg log_firmcount ib4.near_dam##post, fe
eststo firm_2: reghdfe log_firmcount ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)


// **Calculate P-values and Means**
test 1.near_dam#1.post = 2.near_dam#1.post
local pval_5_10 : di %6.3f r(p)

test 1.near_dam#1.post = 3.near_dam#1.post
local pval_5_20 : di %6.3f r(p)

// **Calculate Sample Means for Reference**
sum emp_all_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_emp_all : di %6.2f r(mean)

sum emp_manuf_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_manuf : di %6.2f r(mean)

sum emp_services_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_services : di %6.2f r(mean)

sum cultivators if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_cultivators : di %6.2f r(mean)

sum agri_labourers if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_agrilab : di %6.2f r(mean)

sum marginal_workers if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_marginal_w : di %6.2f r(mean)

sum count_all_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_firm_count : di %6.2f r(mean)

sum population if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_population : di %6.2f r(mean)

// **Export Combined Table to Word (.doc)**
esttab  pop_2 emp_2 emp_2_m emp_2_s cult_2 agri_2  marg_2  using "$data/employed_individuals_30_sector_wise.doc", replace ///
    nodepvar nopa nocon label nogaps nonum ///
    keep(1.near_dam#1.post 2.near_dam#1.post 3.near_dam#1.post) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Summary of Employed Individuals Differences Across Categories") ///
    mtitles( "Population" ///
	       "Total Employment " ///
	         "Manufacturing" ///
			 "Services" ///
             "Cultivators" ///
            "Agri Labourers " ///
            "Marginal Workers ") ///
      s(N r2, label("N" "R-squared")) ///
    varlabels(1.near_dam#1.post "0-5km" ///
              2.near_dam#1.post "5-10km" ///
              3.near_dam#1.post "10-20km") ///
			      se /// 
     note("Test: 0-5km vs 5-10km, p-value = `pval_5_10'. " ///
         "Test: 0-5km vs 10-20km, p-value = `pval_5_20'. " ///
		 "Reference mean (Population)20-30km = `mean_population'." ///
         "Reference mean (Employment)20-30km = `mean_emp_all'. " ///
		 "Reference mean (Manufacturing)20-30km = `mean_manuf'." ///
         "Reference mean (Services)20-30km = `mean_services'." ///
         "Reference mean (Cultivators)20-30km = `mean_cultivators'. " ///
         "Reference mean (Agri Labourers)20-30km = `mean_agrilab'. " ///
         "Reference mean (Marginal Workers)20-30km = `mean_marginal_w'. " ) ///
     
******************** Regression firm size******************


gen log_count_size_20 = log(count_size20_+1) if !missing(post)
gen log_count_size_50 = log(count_size50_+1) if !missing(post)
gen log_count_size_100 =log(count_size100_+1) if !missing(post)
gen log_count_size_101 =log(count_size101_+1) if !missing(post)


*********** Summary Table **********************************			

// **Firm Count**
eststo firm_1: xtreg log_firmcount ib4.near_dam##post, fe
eststo firm_2: reghdfe log_firmcount ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)
// size 20
eststo size_20_1: xtreg log_count_size_20 ib4.near_dam##post, fe
eststo size_20_2: reghdfe log_count_size_20 ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

//size 50
eststo size_50_1: xtreg log_count_size_50  ib4.near_dam##post, fe
eststo size_50_2: reghdfe log_count_size_50 ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

// size 100
eststo size_100_1: xtreg log_count_size_100  ib4.near_dam##post, fe
eststo size_100_2: reghdfe log_count_size_100 ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)
// size 101

eststo size_101_1: xtreg log_count_size_101 ib4.near_dam##post, fe
eststo size_101_2: reghdfe log_count_size_101 ib4.near_dam##post population, absorb(shrid2_code) cluster(name#near_dam)

// **Calculate P-values and Means**
test 1.near_dam#1.post = 2.near_dam#1.post
local pval_5_10 : di %6.3f r(p)

test 1.near_dam#1.post = 3.near_dam#1.post
local pval_5_20 : di %6.3f r(p)


sum count_all_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_firm_count : di %6.2f r(mean)

sum count_size20_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_count_size_20 : di %6.2f r(mean)

sum count_size50_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_count_size_50 : di %6.2f r(mean)

sum count_size100_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_count_size_100 : di %6.2f r(mean)

sum count_size101_ if e(sample) & near_dam == 4 & inrange(completionyear, 1999, 2005)
local mean_count_size_101 : di %6.2f r(mean)



// **Export Combined Table to Word (.doc)**
esttab  firm_2 size_20_2 size_50_2 size_100_2 size_101_2 using "$data/employed_individuals_30_firm_size_wise.doc", replace ///
    nodepvar nopa nocon label nogaps nonum ///
    keep(1.near_dam#1.post 2.near_dam#1.post 3.near_dam#1.post) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Firm  Employee size  Differences ") ///
    mtitles( "Total Firm count" ///
	         " Firm Size - 20 " ///
			 " Firm Size - 50 " ///
			 " Firm Size - 100 " ///
			 " Firm Size - > 101 ") ///
            s(N r2, label("N" "R-squared")) ///
    varlabels(1.near_dam#1.post "0-5km" ///
              2.near_dam#1.post "5-10km" ///
              3.near_dam#1.post "10-20km") ///
			      se /// 
     note("Test: 0-5km vs 5-10km, p-value = `pval_5_10'. " ///
         "Test: 0-5km vs 10-20km, p-value = `pval_5_20'. " ///
		 "Reference mean (Firm Count)20-30km = `mean_firm_count'. " ///
		 "Reference mean (Firm Size -20)20-30km = `mean_count_size_20'. " ///
		  "Reference mean (Firm Size -50)20-30km = `mean_count_size_50'. " ///
		  "Reference mean (Firm Size -100)20-30km = `mean_count_size_100'. " ///
		  "Reference mean (Firm Size -101)20-30km = `mean_count_size_101'. ") 


		
	
****** rough***************
reghdfe log_emp_all ib4.near_dam##b1998.census_year population if !missing(post), absorb(shrid2_code) cluster(name#near_dam) 
coefplot, vertical keep(1.near_dam#*post) xlabel(,angle(45))
coefplot, vertical keep(1.near_dam#*census_year) xlabel(,angle(45))
coefplot, vertical keep(3.near_dam#*census_year) xlabel(,angle(45))

		
* Store each regression result quietly
qui eststo r1: reghdfe log_emp_all  ib4.near_dam##b1998.census_year population if !missing(post), absorb(shrid2_code) cluster(name#near_dam)
qui eststo r2: reghdfe log_emp_all  ib4.near_dam##b1998.census_year population if !missing(post), absorb(shrid2_code) cluster(name#near_dam)
qui eststo r3: reghdfe log_emp_all  ib4.near_dam##b1998.census_year population if !missing(post), absorb(shrid2_code) cluster(name#near_dam)

* Generate combined coefficient plot
coefplot /// 
    (r1, keep(1.near_dam#*.census_year) mcolor(red) ciopts(color(red%33 red%20 red%10))) ///
    (r2, keep(2.near_dam#*.census_year) mcolor(blue) ciopts(color(blue%33 blue%20 blue%10))) ///
    (r3, keep(3.near_dam#*.census_year) mcolor(green) ciopts(color(green%33 green%20 green%10))), ///
    vertical ///
    xlabel(1 "1990" 2 "1998" 3 "2005" 4 "2013" 5 "1990" 6 "1998" 7 "2005" 8 "2013" 9 "1990" 10 "1998" 11 "2005" 12 "2013", angle(45)) ///
    omitted baselevels ///
    ci(90 95 99) ///
    yline(0, lcolor(black) lwidth(medthin))

//// cultivators

* Store each regression result quietly
qui eststo r1: reghdfe  agri_lab_share ib4.near_dam##b1998.census_year  if !missing(post), absorb(subdistrict_code) cluster(name#near_dam)
qui eststo r2: reghdfe  agri_lab_share ib4.near_dam##b1998.census_year  if !missing(post), absorb(subdistrict_code) cluster(name#near_dam)
qui eststo r3: reghdfe  agri_lab_share ib4.near_dam##b1998.census_year  if !missing(post), absorb(subdistrict_code) cluster(name#near_dam)

* Generate combined coefficient plot
coefplot /// 
    (r1, keep(1.near_dam#*.census_year) mcolor(red) ciopts(color(red%33 red%20 red%10))) ///
    (r2, keep(2.near_dam#*.census_year) mcolor(blue) ciopts(color(blue%33 blue%20 blue%10))) ///
    (r3, keep(3.near_dam#*.census_year) mcolor(green) ciopts(color(green%33 green%20 green%10))), ///
    vertical ///
    xlabel(1 "1990" 2 "1998" 3 "2005" 4 "2013" 5 "1990" 6 "1998" 7 "2005" 8 "2013" 9 "1990" 10 "1998" 11 "2005" 12 "2013", angle(45)) ///
    omitted baselevels ///
    ci(90 95 99) ///
    yline(0, lcolor(black) lwidth(medthin))
	
	

