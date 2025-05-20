

********************************************************************************
** 1. Identify data-driven patents
**Select business method patents
**Do not require that they are filed by public companies
**Use all BM patents to identify data-driven ones

cd "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel"

**Get patent filing year and grant year
use "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\general_info\info_2023.dta", clear
	gen fyear = real(reverse(substr(reverse(fdate),1,4)))
	gen iyear = real(reverse(substr(reverse(fdate),1,4)))
	tab fyear
	keep if fyear>=1970 & fyear <=2022
	tab iyear
save "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\general_info\info_2023.dta", replace

use "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\general_info\info_2023.dta", clear	
	gen year = real(reverse(substr(reverse(fdate),1,4)))
	gen month = real(substr(fdate,1,2))
	gen day = real(substr(fdate,4,2))
	gen fday = mdy(month, day, year)
	format fday %d
*	gen test = mdy(1, 10, 1974)
*	gen test1 = fday - test
*	drop test test1
	drop fdate
	drop year month day
	rename fday fdate
	
	gen year = real(reverse(substr(reverse(idate),1,4)))
	gen month = real(substr(idate,1,2))
	gen day = real(substr(idate,4,2))
	gen iday = mdy(month, day, year)
	format iday %d
	drop idate
	rename iday idate	
	drop year month day
save "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\general_info\info_2023.dta", replace
	
**Get patent's classification info
**A patent can belong to multiple tech-classes
**If one tech-class is G06Q, this patent is a business method patent.
use "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\classification\cpc_classification_2023.dta", clear
	gen business_method1 = cpc_subclass == "G06Q" //562k business method patents out of 50 mil
	bysort patnum: egen business_method = max(business_method1)
	keep patnum business_method
	bysort _all: drop if _n>1 //7.4 mil patens, 196k BM patents
**merge with year
	merge 1:1 patnum using "general_info\info_2023.dta", keepusing(fdate)
	keep if _merge == 3
	drop _merge
	gen year = real(reverse(substr(reverse(fdate),1,4)))
	keep if year>1980 & year <=2020
	keep patnum business_method year
	keep if business_method == 1
save "C:\Users\angli\OneDrive - Lingnan University\Data_driven_innovation\Stata\dta\BM_patents_all_202309.dta", replace

use "C:\Users\angli\OneDrive - Lingnan University\Data_driven_innovation\Stata\dta\BM_patents_all_202309.dta", clear
	merge 1:1 patnum using "abstract_title\abstract_title_2023.dta"
	keep if _merge == 3
	drop _merge	
save "C:\Users\angli\OneDrive - Lingnan University\Data_driven_innovation\Stata\dta\BM_patents_all.dta", replace
	
export delimited using "C:\Users\angli\OneDrive - Lingnan University\Data_driven_innovation\Stata\dta\business_method_patents_all192k.csv", replace	

**Use the following python code to calculate cosine similarity
**cosine_similarity_all_BM_231002.py
**
*-------------------------------------------------------------------------------

cd "C:\Users\angli\OneDrive - Lingnan University\Data_driven_innovation\Stata\do"
	
**Calculate similarity in python
**Import similarity score to Stata
import excel "..\..\Python\Cosine_bm_patents_business_202310.xlsx", sheet("Sheet1") firstrow clear
	keep patnum strings cosine
	rename cosine cosine_business
save "..\dta\cosine_202310.dta"

import excel "..\..\Python\Cosine_bm_patents_data_202310.xlsx", sheet("Sheet1") firstrow clear
	keep patnum strings cosine
	rename cosine cosine_data	
	merge 1:1 patnum using "..\dta\cosine_202310.dta"
	keep if _merge == 3
	drop _merge
save "..\dta\cosine_202310.dta", replace

**Identify labels for the classification model
use "..\dta\cosine_202310.dta", clear
	sort cosine_data
	drop if cosine_data==0 //have missing abstracts
	gen Data_simi_rank = _N - _n + 1
	sort cosine_business
	drop if cosine_business==0 //have missing abstracts
	gen Business_simi_rank = _N - _n + 1

	gen top_d = Data_simi_rank <= 192094*0.11
	gen top_b = Business_simi_rank <= 192094*0.11
	gen top = 1 if top_d == 1 & top_b == 1
	replace top = 0 if top_d != 1 | top_b != 1
	tab top
	
	gen bottom_d = Data_simi_rank > 192094-192094*0.05
	gen bottom_b = Business_simi_rank > 192094-192094*0.05
	gen bottom = 1 if bottom_d == 1 & bottom_b == 1
	replace bottom = 0 if bottom_d != 1 | bottom_b != 1	
	tab bottom
	
	gen label = 1 if top == 1
	replace label = 0 if bottom ==1
	sort label
	keep patnum strings label
export delimited using "C:\Users\angli\OneDrive - Lingnan University\Data_driven_innovation\Stata\dta\BM_patents_all_label_202310.csv", replace
	
*******************************************************************************
**Use Python to classify business method patents, generate a prediction score
**Import into Stata
import excel "C:\Users\angli\OneDrive - Lingnan University\Data_driven_innovation\Python\BM_patents_prediction_new_allBM_202310.xlsx", sheet("Sheet1") firstrow clear //192k obs
	replace predictions = subinstr(predictions, "[", "", .) 
	replace predictions = subinstr(predictions, "]", "", .) 
	destring predictions, gen(a)
	drop predictions
	rename a predictions

	hist predictions, freq
	count if predictions>0.99  & predictions<=1
	count if predictions>0.98  & predictions<0.99
	count if predictions>0.97  & predictions<0.98
	count if predictions>0.96  & predictions<0.97
	count if predictions>0.95  & predictions<0.96
	count if predictions>0.94  & predictions<0.95
	count if predictions>0.93  & predictions<0.94
	count if predictions>0.92  & predictions<0.93
	count if predictions>0.91  & predictions<0.92
	count if predictions>0.9  & predictions<0.91
	count if predictions>0.89  & predictions<0.9
	count if predictions<0.01
	
	gen ddbm = 1 if predictions >=0.99
	keep patnum ddbm
save "..\dta\patnum_ddbm.dta", replace

use "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\patnum_permco_1976_2022.dta"
	destring patnum, replace force
	drop if patnum == .
	bysort patnum: gen dup = cond(_N==1, 0, _n)
	drop if dup > 0 // if a patent is owned by more than one firms
	drop dup
	
	merge 1:1 patnum using "..\dta\patnum_ddbm.dta" //merge with all patents filed by Compustat firms
	replace ddbm = 0 if missing(ddbm)
	drop if _merge == 2 //drop patents not filed by compustat firms
	drop _merge	
save "..\dta\permco_patnum_ddbm.dta", replace //35,947 DDBM

**Find patents that cite the ddbm patents
**If a patent directly cited a ddbm patent, we label it as a ddbm patent.	
use "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\cites\citation.dta", clear
	rename (patnum patcite_num) (patciting_num patnum)
	merge m:1 patnum using "..\dta\patnum_ddbm.dta", keepusing(ddbm)
	keep if _merge == 3
	drop _merge
	keep if ddbm == 1
	drop patnum
	bysort patciting_num: drop if _n>1
	rename patciting_num patnum
	keep patnum 
	merge 1:1 patnum using "..\dta\permco_patnum_ddbm.dta"
	drop if _merge == 1
	replace ddbm = 1 if _merge == 3
	drop _merge	
	gen year = real(reverse(substr(reverse(fdate),1,4)))
	keep if year>=1981 & year <=2022
	
save "..\dta\permco_patnum_ddbm.dta", replace	//191k ddbm patents
		
	tab ddbm // 176,100 out of 2.6 million patents // when using 0.99 prediction score cutoff		
	tab ddbm // 191,061 out of 2.6 million patents // when using 0.9 prediction score cutoff

********************************************************************************
*-------------------------------------------------------------------------------
**Calculate citation-weighted number of patents
**Calculate the number of citations a patent receives ending three years after the grant date.
use "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\cites\citation.dta", clear
**Merge with patents' filing date and grant date
	merge m:1 patnum using "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\general_info\info_2023.dta", keepusing(fdate idate)
	keep if _merge == 3
	drop _merge
	rename fdate citing_fdate
	rename idate citing_idate
*
	rename patnum patnum_citing
	rename patcite_num patnum
	merge m:1 patnum using "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\general_info\info_2023.dta", keepusing(fdate idate)
	keep if _merge == 3
	drop _merge
	rename idate cited_idate
	rename fdate cited_fdate
	rename patnum patnum_cited 
	
	gen window = citing_fdate - cited_idate
	keep if window <= 365*3
	bysort patnum_cited: egen n_cites = nvals(patnum_citing)

	keep patnum_cited n_cites
	bysort patnum_cited: drop if _n>1
	rename patnum_cited patnum  
save "..\dta\cites_3yr.dta", replace

*-----------------------------------
use "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\cites\citation.dta", clear
**Merge with patents' filing date and grant date
	merge m:1 patnum using "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\general_info\info_2023.dta", keepusing(fdate idate)
	keep if _merge == 3
	drop _merge
	rename fdate citing_fdate
	rename idate citing_idate
*
	rename patnum patnum_citing
	rename patcite_num patnum
	merge m:1 patnum using "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\general_info\info_2023.dta", keepusing(fdate idate)
	keep if _merge == 3
	drop _merge
	rename idate cited_idate
	rename fdate cited_fdate
	rename patnum patnum_cited 
	
	gen window = citing_fdate - cited_idate
	keep if window <= 365*5
	bysort patnum_cited: egen n_cites = nvals(patnum_citing)

	keep patnum_cited n_cites
	bysort patnum_cited: drop if _n>1
	rename patnum_cited patnum  
save "..\dta\cites_5yr.dta", replace

*******************************************************************************
**Calculate the number of patents by firm
use "..\dta\permco_patnum_ddbm.dta", clear
	rename patnum patent_num 
	merge 1:1 patent_num using "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Stoffman\KPSS_2022", keepusing(xi_real)
	drop if _merge == 2
	drop _merge
	rename patent_num patnum  	
save "..\dta\permco_patnum_ddbm.dta", replace  

use "..\dta\permco_patnum_ddbm.dta", clear
	bysort permco year: egen firm_npat = nvals(patnum)	
	bysort permco year: egen firm_pat_value = sum(xi_real)	
	merge 1:1 patnum using "..\dta\cites_5yr.dta"
	drop if _merge == 2
	drop _merge
	replace n_cites = 0 if missing(n_cites)
	bysort permco year: egen firm_ncites = sum(n_cites)	
	
	keep permco year firm_npat firm_pat_value firm_ncites
	bysort permco year: drop if _n>1
save "..\dta\permco_npat.dta", replace //64k obs

use "..\dta\permco_patnum_ddbm.dta", clear
	keep if ddbm == 1
	bysort permco year: egen firm_npat_ddbm = nvals(patnum)	
	keep permco year firm_npat_ddbm
	bysort permco year: drop if _n>1
	merge 1:1 permco year using "..\dta\permco_npat.dta"
	replace firm_npat_ddbm = 0 if _merge == 2
	drop _merge
	gen ddbm_share = firm_npat_ddbm/firm_npat
save "..\dta\permco_npat.dta", replace

*******************************************************************************
**Calculate the value of patents by firm
use "..\dta\permco_patnum_ddbm.dta", clear
	bysort permco year patnum: drop if _n>1 //0 dropped
	keep if ddbm == 1
	bysort permco year: egen firm_pat_value_ddbm = sum(xi_real)	
	keep permco year firm_pat_value_ddbm	
	bysort permco year: drop if _n>1
	merge 1:1 permco year using "..\dta\permco_npat.dta"
	replace firm_pat_value_ddbm = 0 if _merge == 2
	drop _merge
save "..\dta\permco_npat.dta", replace
	
*******************************************************************************
**Calculate the citations of patents by firm
use "..\dta\permco_patnum_ddbm.dta", clear
	merge 1:1 patnum using "..\dta\cites_5yr.dta"
	drop if _merge == 2
	drop _merge
	replace n_cites = 0 if missing(n_cites)

	keep if ddbm == 1
	bysort permco year: egen firm_ncites_ddbm = sum(n_cites)	
	keep permco year firm_ncites_ddbm	
	bysort permco year: drop if _n>1
	merge 1:1 permco year using "..\dta\permco_npat.dta"
	replace firm_ncites_ddbm = 0 if _merge == 2
	drop _merge
save "..\dta\permco_npat.dta", replace

	
*******************************************************************************
**Find examples of DDBM patents	
cd "C:\Users\angli\OneDrive - Lingnan University\Data_driven_innovation\Stata\do"

use "..\dta\conglo_pat_q_ddi.dta", clear	
	keep permco year ff48ind ff10ind
	bysort permco year: drop if _n > 1
save "..\dta\temp1.dta", replace

use "..\dta\permco_patnum_ddbm.dta", clear	
	merge m:1 permco year using "..\dta\temp1.dta"
	keep if _merge == 3
	drop _merge	
	merge 1:1 patnum using "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\abstract_title\abstract_title_2023.dta"
	keep if _merge == 3
	drop _merge
	
	keep if ddbm == 1
	gsort - xi_real
save "..\dta\temp1.dta", replace

use "C:\Users\angli\OneDrive - Lingnan University\Raw data\CRSP\permco_name.dta", clear	
	rename _all, lower
	gen year = year(date)
	drop if comnam == ""
	keep permco year comnam
	bysort permco year: drop if _n>1
save "C:\Users\angli\OneDrive - Lingnan University\Raw data\CRSP\permco_name.dta", replace

use "..\dta\temp1.dta", clear	
	merge n:1 permco year using "C:\Users\angli\OneDrive - Lingnan University\Raw data\CRSP\permco_name.dta"
	keep if _merge == 3
	drop _merge	
	gsort - xi_real
	drop ddbm
	
	gen FamaFrench10 = "1Nondurables" if ff10ind == 1
	replace FamaFrench10 = "2Durables" if ff10ind == 2
	replace FamaFrench10 = "3Manufacturing" if ff10ind == 3
	replace FamaFrench10 = "4Energy" if ff10ind == 4
	replace FamaFrench10 = "5HiTech" if ff10ind == 5
	replace FamaFrench10 = "6Telecome" if ff10ind == 6
	replace FamaFrench10 = "7Shops" if ff10ind == 7
	replace FamaFrench10 = "8Health" if ff10ind == 8
	replace FamaFrench10 = "9Utilities" if ff10ind == 9
	replace FamaFrench10 = "Others" if ff10ind == 10
	
	br if strpos(comnam, "HONEYWELL") > 0
br

********************************************************************************
**Does DDI have more generality?
use "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\patnum_permco_1976_2022.dta", clear
	gen year = real(reverse(substr(reverse(fdate),1,4)))
	gen month = real(substr(fdate,1,2))
	gen day = real(substr(fdate,4,2))
	gen fday = mdy(month, day, year)
	format fday %d
*	gen test = mdy(1, 10, 1974)
*	gen test1 = fday - test
*	drop test test1
	drop fdate
	drop year month day
	rename fday fdate
	
	gen year = real(reverse(substr(reverse(idate),1,4)))
	gen month = real(substr(idate,1,2))
	gen day = real(substr(idate,4,2))
	gen iday = mdy(month, day, year)
	format iday %d
	gen test = mdy(1, 06, 1975)
	gen test1 = iday - test
	drop test test1
	drop idate
	rename iday idate	
	drop year month day

	** Duplicate patents: some are owned by multiple firms.
	by patnum, sort: gen dup=cond(_N==1,0,_n)
	drop if dup!=0 //few dropped
	drop dup
	** keep patents that are eventually granted
	drop if idate== . //0 dropped
	drop if permco== .
	destring patnum, force replace // dropped design patents starting with "D"	
	drop if patnum==.
save "..\dta\patents_permco.dta", replace //patnum permco fdate idate

**Get patent's classification info
use "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\classification\cpc_classification_2023.dta", clear
	keep if cpc_sequence == 0 // The sequence starts at 0 for all patents
* 	keep patnum cpc_class // 132 unique class; 639 unique sub-class
	keep patnum cpc_subclass // 132 unique class; 639 unique sub-class
*	keep patnum cpc_group // many groups.
 *	rename cpc_class class
	rename cpc_subclass  class
save "..\dta\temp2.dta", replace	

use "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\cites\citation.dta", clear
**Get cited patents' grant date
	gen year = real(reverse(substr(reverse(patcite_idate),1,4)))
	gen month = real(substr(patcite_idate,1,2))
	drop if year>2022
	drop if year<1900
	gen yrm_cited = ym(year, month)
	drop month year 
	destring patnum, replace
	destring patcite_num, force replace
	keep patnum patcite_num
	drop if patnum==. | patcite_num==.	
save "..\dta\citation.dta", replace

use "..\dta\citation.dta", clear
	rename patnum patnum_citing
	rename patcite_num patnum
*Information of the patentes being cited	
*patents of public firms that have a permco
	merge m:1 patnum using "..\dta\patents.dta"
	keep if _merge==3
	drop _merge
	drop if permco==.
	rename permco permco_cited
	rename fdate fdate_cited
	rename idate idate_cited
	rename patnum patnum_cited
*Information of the patentes citing others
*include all patents filed by firms with or without permco
	rename patnum_citing patnum
	merge m:1 patnum using "..\dta\patents.dta", keepusing(permco)
	drop if _merge == 2
	drop _merge
	rename permco permco_citing
	
*citing patents dates	
	merge m:1 patnum using "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\general_info\info_2023.dta", keepusing(fdate idate)
	keep if _merge == 3
	drop _merge
	rename fdate fdate_citing
	rename idate idate_citing
	rename patnum patnum_citing 

** merge patents being cited with tech class
	rename patnum_cited patnum  
	merge m:1 patnum using "..\dta\temp2.dta"
	keep if _merge==3
	drop _merge
	drop if class==""
	rename class class_cited
	rename patnum patnum_cited   
	
** merge citing patents with tech class
	rename patnum_citing patnum  
	merge m:1 patnum using "..\dta\temp2.dta"
	keep if _merge==3
	drop _merge
	drop if class==""
	rename class class_citing
	rename patnum patnum_citing   
save "..\dta\general.dta", replace

use "..\dta\general.dta", clear
	keep if year(fdate_cited)>=1921
	keep if year(fdate_cited)<=2022
save "..\dta\general.dta", replace

********************************************************************************
**Firm level measures
********************************************************************************
use "..\dta\general.dta", clear
	keep if fdate_citing - idate_cited < 365*5
	gen fyear_cited = year(fdate_cited)
	
	rename patnum_cited patnum
	merge n:1 patnum using "..\dta\permco_patnum_ddbm.dta", keepusing(ddbm)
	keep if _merge == 3
	drop _merge
	
	bysort permco_cited fyear_cited ddbm: egen n_cites = nvals(patnum_citing) 
	bysort permco_cited fyear_cited ddbm: egen n_class = nvals(class_citing) 
	bysort permco_cited fyear_cited ddbm class_citing: egen cited_n_class = nvals(patnum_citing)
	bysort permco_cited fyear_cited ddbm class_citing: drop if [_n]>1 
	keep permco_cited fyear_cited ddbm n_cites n_class class_citing cited_n_class
	gen share = cited_n_class/n_cites
	gen share2 = share*share
	bysort permco_cited fyear_cited ddbm: egen hhi = sum(share2)
	bysort permco_cited fyear_cited ddbm: drop if [_n]>1 
	gen generality = 1-hhi
	keep permco_cited fyear_cited ddbm n_cites n_class generality
	reshape wide n_cites n_class generality, i(permco_cited fyear_cited) j(ddbm)
	rename (n_cites0 n_class0 generality0) (n_cites_nonddbm n_class_nonddbm generality_nonddbm)
	rename (n_cites1 n_class1 generality1) (n_cites_ddbm n_class_ddbm generality_ddbm)
	
foreach var of varlist n_cites_nonddbm n_class_nonddbm generality_nonddbm n_cites_ddbm n_class_ddbm generality_ddbm{
	replace `var' = 0 if missing(`var')
}	
	rename permco_cited permco
	rename  fyear_cited year
save "..\dta\generality_permco_cpc_subclass.dta", replace



********************************************************************************
**Patent level measures
**
** Generality
** Out of class cites
** Self cites
** claims
**
********************************************************************************
use "..\dta\general.dta", clear
	keep if fdate_citing - idate_cited < 365*5
	bysort patnum_cited: egen n_cites = nvals(patnum_citing) 
	bysort patnum_cited: egen n_class = nvals(class_citing) 
	bysort patnum_cited class_citing: egen cited_n_class = nvals(patnum_citing)
	bysort patnum_cited class_citing: drop if [_n]>1 
	keep patnum_cited n_cites n_class class_citing cited_n_class
	gen share = cited_n_class/n_cites
	gen share2 = share*share
	bysort patnum_cited: egen hhi = sum(share2)
	bysort patnum_cited: drop if [_n]>1 
	gen generality = 1-hhi
	keep patnum_cited n_cites n_class generality
save "..\dta\generality_patnum_cpc_subclass.dta", replace

**Out of class cites
use "..\dta\general.dta", clear
	keep if fdate_citing - idate_cited < 365*5
	drop if class_citing == class_cited // 10/18 dropped
	bysort patnum_cited: egen n_cites_outclass = nvals(patnum_citing) //median 12, mean 31
	bysort patnum_cited: drop if [_n]>1 
	keep patnum_cited n_cites_outclass
	merge 1:1 patnum_cited using "..\dta\generality_patnum_cpc_subclass.dta"
	replace n_cites_outclass = 0 if _merge == 2
	drop _merge
	gen cites_out_of_class = n_cites_outclass / n_cites //median 0.4 mean 0.45
save "..\dta\generality_patnum_cpc_subclass.dta", replace

** Self cites.
use "..\dta\general.dta", clear
	keep if fdate_citing - idate_cited < 365*5
	keep if permco_cited == permco_citing // 14/19 dropped
	bysort patnum_cited: egen n_cites_self = nvals(patnum_citing) //median 11, mean 78
	bysort patnum_cited: drop if [_n]>1 
	keep patnum_cited n_cites_self
	merge 1:1 patnum_cited using "..\dta\generality_patnum_cpc_subclass.dta"
	replace n_cites_self = 0 if _merge == 2
	drop _merge
	gen cites_self = n_cites_self / n_cites //median 0 mean 0.22
save "..\dta\generality_patnum_cpc_subclass.dta", replace
	
use "..\dta\firm_segments.dta", clear
	keep permco conglo fyear  
	bysort permco fyear: drop if [_n]>1
	rename fyear year
save "..\dta\temp1.dta", replace

use "..\dta\permco_patnum_ddbm.dta", clear
	merge 1:1 patnum using "C:\Users\angli\OneDrive - Lingnan University\Raw data\Innovation\Mike_Woeppel\claims\claims_2025.dta"
	keep if _merge == 3
	drop _merge
		
	merge n:1 permco year using "..\dta\temp1.dta"
	drop if _merge == 2
	drop _merge
	rename patnum patnum_cited
	merge 1:1 patnum_cited using "..\dta\generality_patnum_cpc_subclass.dta"
	drop if _merge == 2
*	replace n_cites = 0 if _merge == 1
*	replace n_class = 0 if _merge == 1
*	replace generality = 0 if _merge == 1
	drop _merge
save "..\dta\temp1.dta", replace
	
/*	
	keep if conglo == 1
	collapse generality, by(ddbm year)
	ttest generality, by(ddbm)
*/		
use "..\dta\temp1.dta", clear
	keep if year>=1981 & year<=2020
	ttest xi_real, by(ddbm)
	ttest n_cites, by(ddbm)
	ttest n_class if conglo == 1, by(ddbm)
	ttest generality if conglo == 0 , by(ddbm)
	ttest cites_out_of_class if conglo == 0  , by(ddbm)
	ttest cites_self if conglo == 0  , by(ddbm)

	collapse n_cites xi_real n_class generality cites_out_of_class cites_self short_claim_count first_claim_count avg_claim_count dep_claims ind_claims, by(ddbm year)
	
foreach var of varlist n_cites xi_real n_class generality cites_out_of_class cites_self short_claim_count first_claim_count avg_claim_count dep_claims ind_claims {
	ttest `var', by(ddbm)
	local diff = r(mu_1) - r(mu_2)	
	matrix ttest= (r(mu_1), r(N_1), r(mu_2), r(N_2), `diff', r(t))
	matrix rownames ttest= `var'
	matrix colnames ttest= Non-DDI N1 DDI N2 diff t
	mat2txt, matrix(ttest) sav("..\tables\table1b1.xls") append	
}

**Conglomerates
use "..\dta\temp1.dta", clear
	keep if year>=1981 & year<=2020
	keep if conglo == 1
	collapse n_cites xi_real n_class generality cites_out_of_class cites_self short_claim_count first_claim_count avg_claim_count dep_claims ind_claims, by(ddbm year)
foreach var of varlist n_cites xi_real n_class generality cites_out_of_class cites_self short_claim_count first_claim_count avg_claim_count dep_claims ind_claims {
	ttest `var', by(ddbm)
	local diff = r(mu_1) - r(mu_2)	
	matrix ttest= (r(mu_1), r(N_1), r(mu_2), r(N_2), `diff', r(t))
	matrix rownames ttest= `var'
	matrix colnames ttest= Non-DDI N1 DDI N2 diff t
	mat2txt, matrix(ttest) sav("..\tables\table1b2.xls") append	
}	
	
**Pureplays
use "..\dta\temp1.dta", clear
	keep if year>=1981 & year<=2020
	keep if conglo == 0
	collapse n_cites xi_real n_class generality cites_out_of_class cites_self short_claim_count first_claim_count avg_claim_count dep_claims ind_claims, by(ddbm year)
foreach var of varlist n_cites xi_real n_class generality cites_out_of_class cites_self short_claim_count first_claim_count avg_claim_count dep_claims ind_claims {
	ttest `var', by(ddbm)
	local diff = r(mu_1) - r(mu_2)	
	matrix ttest= (r(mu_1), r(N_1), r(mu_2), r(N_2), `diff', r(t))
	matrix rownames ttest= `var'
	matrix colnames ttest= Non-DDI N1 DDI N2 diff t
	mat2txt, matrix(ttest) sav("..\tables\table1b3.xls") append	
}	
	










	
