gen double total=real(subinstr(ustrtrim(v228),",","",.))
gen double asset1=real(subinstr(ustrtrim(v93),",","",.))
gen double asset2=real(subinstr(ustrtrim(v95),",","",.))
gen double asset3=real(subinstr(ustrtrim(v97),",","",.))
gen double asset4=real(subinstr(ustrtrim(v98),",","",.))
gen double asset5=real(subinstr(ustrtrim(v100),",","",.))
gen double asset6=real(subinstr(ustrtrim(v101),",","",.))
gen double asset7=real(subinstr(ustrtrim(v103),",","",.))
gen double asset8=.
egen byte missing_components=rowmiss(asset1 asset2 asset3 asset4 asset5 asset6 asset7)
gen byte complete=missing_components==0
egen double component_sum=rowtotal(asset1 asset2 asset3 asset4 asset5 asset6 asset7)
replace component_sum=. if !complete
egen double min_component=rowmin(asset1 asset2 asset3 asset4 asset5 asset6 asset7)
gen byte has_negative_component=min_component<0
keep source_row total asset* complete component_sum has_negative_component
gen int year=2019
