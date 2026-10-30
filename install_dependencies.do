version 16.1
* Run from this repository root. Third-party software stays local and ignored.
capture mkdir vendor
capture mkdir vendor/st0444
net set ado "vendor/st0444"
net install st0444, from("https://www.stata-journal.com/software/sj16-3") replace
ssc install moremata, replace
ssc install kdens, replace
display "DEPENDENCIES_DOWNLOADED"
