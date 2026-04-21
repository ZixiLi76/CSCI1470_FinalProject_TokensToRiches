
clear all
set more off
capture log close
version 17

cd "/Users/zixili/Desktop/Brown/Spring_2026/CSCI_1470/FinalProject"

log using "prep.log", text replace
timer clear 1
timer on  1




use "PSIDSHELF_1968_2021_LONG.dta", clear
count
display as result "Loaded: " _N " person-year rows"
save "_full_panel.dta", replace



* Parental Features
keep if REFCOUPLE == 1
keep if inrange(DEMO_BIRTH_YEAR, 1960, 1975)
keep ID DEMO_BIRTH_YEAR REL_PAR_BF_ID REL_PAR_BM_ID
duplicates drop
gen yr_lo = DEMO_BIRTH_YEAR + 10
gen yr_hi = DEMO_BIRTH_YEAR + 18
count
display as result _N " egos in the 1960-1975 refcouple cohort"
save "_egos.dta", replace
*10948 egos in the 1960-1975 refcouple cohort


* Father Features
use "_full_panel.dta", clear
keep ID YEAR EARN_TOT_RDF FINC_TOT_RDF EDU_LEVEL_MAX FAM_MARSTAT
rename ID    REL_PAR_BF_ID
rename YEAR  parent_YEAR
foreach v in EARN_TOT_RDF FINC_TOT_RDF EDU_LEVEL_MAX FAM_MARSTAT {
    rename `v' f_`v'
}
joinby REL_PAR_BF_ID using "_egos.dta"
keep if inrange(parent_YEAR, yr_lo, yr_hi)

gen _f_married  = (f_FAM_MARSTAT == 1)
gen _f_divorced = inlist(f_FAM_MARSTAT, 2, 3)

collapse (mean)  father_EARN_mean     = f_EARN_TOT_RDF   ///
                  father_FINC_mean     = f_FINC_TOT_RDF   ///
                  father_share_married = _f_married       ///
                  father_share_divorc  = _f_divorced      ///
         (sd)     father_EARN_sd       = f_EARN_TOT_RDF   ///
         (max)    father_EDU_MAX       = f_EDU_LEVEL_MAX  ///
         (count)  father_obs_cnt       = f_EARN_TOT_RDF,  ///
         by(ID)
save "_fathers.dta", replace
* 3,203 rows



* Mother Features
use "_full_panel.dta", clear
keep ID YEAR EARN_TOT_RDF FINC_TOT_RDF EDU_LEVEL_MAX FAM_MARSTAT
rename ID    REL_PAR_BM_ID
rename YEAR  parent_YEAR
foreach v in EARN_TOT_RDF FINC_TOT_RDF EDU_LEVEL_MAX FAM_MARSTAT {
    rename `v' m_`v'
}

joinby REL_PAR_BM_ID using "_egos.dta"
keep if inrange(parent_YEAR, yr_lo, yr_hi)

gen _m_married  = (m_FAM_MARSTAT == 1)
gen _m_divorced = inlist(m_FAM_MARSTAT, 2, 3)

collapse (mean)  mother_EARN_mean     = m_EARN_TOT_RDF   ///
                  mother_FINC_mean     = m_FINC_TOT_RDF   ///
                  mother_share_married = _m_married       ///
                  mother_share_divorc  = _m_divorced      ///
         (sd)     mother_EARN_sd       = m_EARN_TOT_RDF   ///
         (max)    mother_EDU_MAX       = m_EDU_LEVEL_MAX  ///
         (count)  mother_obs_cnt       = m_EARN_TOT_RDF,  ///
         by(ID)
save "_mothers.dta", replace
*4,347 rows


* Sample Filters
use "_full_panel.dta", clear

keep if REFCOUPLE == 1
count
display as result "After REFCOUPLE==1: " _N " rows"
* After REFCOUPLE==1: 487555 rows

keep if inrange(DEMO_BIRTH_YEAR, 1960, 1975)
count
display as result "After cohort 1960-1975: " _N " rows"
* After cohort 1960-1975: 96077 rows


keep if inrange(DEMO_AGE_GEN, 20, 45)
count
display as result "After ages 20-45: " _N " rows"
* After ages 20-45: 77833 rows






* Coverage filter: >= 8 waves at 20-40 AND >= 2 waves at 41-45
gen _in_input  = inrange(DEMO_AGE_GEN, 20, 40)
gen _in_target = inrange(DEMO_AGE_GEN, 41, 45)
bysort ID: egen n_in = total(_in_input)
bysort ID: egen n_tg = total(_in_target)
keep if n_in >= 8 & n_tg >= 2
drop _in_input _in_target n_in n_tg
count
display as result "After coverage filter: " _N " rows"
* After coverage filter: 38286 rows


preserve
    keep ID
    duplicates drop
    count
    display as result "Unique egos surviving: " _N
restore
* Unique egos surviving: 2585
* 2,585 egos is on the low end for deep learning but workable. With a 50/25/25 split that's ~1,290 train / ~645 val / ~645 test.


* Zachk, if you think we don't have enough here, I can relax n_in >= 8 to n_in >= 6
* Zachk, if keeping 8, try to avoid overfitting at LSTM





* Keep only the variables we export
keep ID YEAR DEMO_BIRTH_YEAR DEMO_AGE_GEN                       ///
     DEMO_SEX RACE_ETH_MAJ_COL CGEO_REGION                      ///
     REL_PAR_BF_ID REL_PAR_BM_ID                                ///
     EARN_TOT_RDF FINC_TOT_RDF                                  ///
     WLTH_TOT_NET_RDF WLTH_HOME_NET_RDF WLTH_SAVI_NET_RDF       ///
     WLTH_INVE_NET_RDF WLTH_ODEB_NET_RDF                        ///
     EMP_WORK EDU_LEVEL                                         ///
     FAM_PARSTAT FAM_MARSTAT FAM_SIZE FAM_SIZE_CHI              ///
     HOME_STAT GEO_REGION GEO_METRO                             ///
     OCC_1970C OCC_2000C_1M OCC_2010C_1M

* Unified occupation — whichever coding is populated this year
gen OCC_ANY = OCC_1970C
replace OCC_ANY = OCC_2000C_1M if missing(OCC_ANY) & !missing(OCC_2000C_1M)
replace OCC_ANY = OCC_2010C_1M if missing(OCC_ANY) & !missing(OCC_2010C_1M)
gen byte OCC_SCHEME = cond(!missing(OCC_1970C),     1,  ///
                       cond(!missing(OCC_2000C_1M), 2,  ///
                       cond(!missing(OCC_2010C_1M), 3, .)))
					   
* After this, in total 6,595 still-missing (~17%), normal.

* Zachk, OCC_1970C, OCC_2000C_1M, OCC_2010C_1M use different coding
* schemes — integer 45 in the 1970 scheme is NOT the same job as 45 in the 2010 scheme. Embed the three columns separately in PyTorch (three nn.Embedding layers), not as one shared vocab on OCC_ANY. OCC_SCHEME tells you which column is active in that row; the other two will be missing by design.
* OCC_ANY is provided only as a sanity-check baseline.





* Merge Parental Features
merge m:1 ID using "_fathers.dta", keep(master match) nogen
merge m:1 ID using "_mothers.dta", keep(master match) nogen
gen byte PAR_BOTH_MISS = missing(father_EARN_mean) & missing(mother_EARN_mean)

* 42% of egos have no father data in the window and 29% have no mother data

preserve
    keep ID PAR_BOTH_MISS
    duplicates drop
    tab PAR_BOTH_MISS
restore
* 34% is higher than I'd love to see but it's workable
* 34% means 1,711 egos with at least one parent's data (66%)
* 874 egos with neither parent tracked during ages 10–18 (34%)

* Zachk, I would recommend keeping everyone. Dropping the 874 egos would mean cutting a third of the already-small sample.



* Winsorize (1/99) + signed-log transform on dollar variables
* signed-log: sign(x) * log(1 + |x|/1000)

local dollar_vars                                              ///
    EARN_TOT_RDF FINC_TOT_RDF                                  ///
    WLTH_TOT_NET_RDF WLTH_HOME_NET_RDF WLTH_SAVI_NET_RDF       ///
    WLTH_INVE_NET_RDF WLTH_ODEB_NET_RDF                        ///
    father_EARN_mean father_EARN_sd father_FINC_mean           ///
    mother_EARN_mean mother_EARN_sd mother_FINC_mean

foreach v of local dollar_vars {
    quietly _pctile `v' if !missing(`v'), p(1 99)
    local lo = r(r1)
    local hi = r(r2)
    display as text "`v': p1 = " %12.0fc `lo' "    p99 = " %12.0fc `hi'
    replace `v' = `lo' if `v' < `lo' & !missing(`v')
    replace `v' = `hi' if `v' > `hi' & !missing(`v')
    generate double _slog = sign(`v') * log(1 + abs(`v')/1000)
    drop `v'
    rename _slog `v'
}




* Birth cohort bin: 0=1960-64, 1=1965-69, 2=1970-75
gen byte COHORT_BIN = 0
replace  COHORT_BIN = 1 if inrange(DEMO_BIRTH_YEAR, 1965, 1969)
replace  COHORT_BIN = 2 if inrange(DEMO_BIRTH_YEAR, 1970, 1975)





* Random 50/25/25 split on ID (fixed seed)
preserve
    keep ID
    duplicates drop
    set seed 1470
    gen double u = runiform()
    gen str5 split = cond(u < 0.50, "train", cond(u < 0.75, "val", "test"))
    drop u
    count
    display as result "Total egos in splits: " _N
    tabulate split
    export delimited ID split using "splits.csv", replace
    save "_splits.dta", replace
restore

merge m:1 ID using "_splits.dta", keep(master match) nogen

* Total egos in splits: 2585

* tabulate split

*      split |      Freq.     Percent        Cum.
*------------+-----------------------------------
*       test |        641       24.80       24.80
*      train |      1,301       50.33       75.13
*        val |        643       24.87      100.00
*------------+-----------------------------------
*      Total |      2,585      100.00




sort ID DEMO_AGE_GEN YEAR
count
display as result "Final rows to export: " _N
* Final rows to export: 38286


describe, fullnames

export delimited using "psid_panel.csv", replace nolabel




foreach f in _full_panel _egos _fathers _mothers _splits {
    capture erase "`f'.dta"
}

timer off 1
timer list 1
log close














