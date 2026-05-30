/*
-------------------------------------------------------------------------------------------------
Pobranie danych z api
-------------------------------------------------------------------------------------------------
*/

filename wynagr temp;

proc http
    method="GET"
    url='https://bdl.stat.gov.pl/api/v1/data/by-variable/64428?year=2021&year=2022&year=2023&year=2024&year=2025&year=2026&year=2027&unit-level=2&format=json&page-size=100'
    out=wynagr;
run;

libname bld_wyn json fileref=wynagr;

filename bezrob temp;

proc http
    method="GET"
    url='https://bdl.stat.gov.pl/api/v1/data/by-variable/60270?year=2021&year=2022&year=2023&year=2024&year=2025&year=2026&year=202&unit-level=2&format=json&page-size=100'
    out=bezrob;
run;

libname bld_bez json fileref=bezrob;

/*
-------------------------------------------------------------------------------------------------
Przekształcenie danych o wynagrodzeniach
-------------------------------------------------------------------------------------------------
*/

data tab_wynagrodzenia_tmp1;
    set bld_wyn.results;
run;

data tab_wynagrodzenia_tmp2;
    set bld_wyn.results_values;
run;

proc sql;
create table tab_wynagrodzenia as
select distinct
    a.ordinal_results as id
    ,a.name as wojewodztwo_napis
    ,b.year as rok
    ,b.val as przecietne_wynagrodzenie
from tab_wynagrodzenia_tmp1 a
left join tab_wynagrodzenia_tmp2 b on a.ordinal_results = b.ordinal_results
order by a.ordinal_results, a.name, b.year
;quit;

proc delete data=tab_wynagrodzenia_tmp1; run;
proc delete data=tab_wynagrodzenia_tmp2; run;

/*
-------------------------------------------------------------------------------------------------
Przekształcenie danych o bezrobociu
-------------------------------------------------------------------------------------------------
*/

data tab_bezrobocie_tmp1;
    set bld_bez.results;
run;

data tab_bezrobocie_tmp2;
    set bld_bez.results_values;
run;

proc sql;
create table tab_bezrobocie as
select distinct
    a.ordinal_results as id
    ,a.name as wojewodztwo_napis
    ,b.year as rok
    ,round(b.val / 100, .0001) format = percent10.2 as stopa_bezrobocia
from tab_bezrobocie_tmp1 a
left join tab_bezrobocie_tmp2 b on a.ordinal_results = b.ordinal_results
order by a.ordinal_results, a.name, b.year
;quit;

proc delete data=tab_bezrobocie_tmp1; run;
proc delete data=tab_bezrobocie_tmp2; run;

/*
-------------------------------------------------------------------------------------------------
Podstawowe dostepne dane
-------------------------------------------------------------------------------------------------
*/

proc sql;
create table tab_podstawowe_dane as
select distinct
    *
from
(
    select
        a.wojewodztwo_napis
        ,a.rok
    from tab_wynagrodzenia a
    union all
    select
        a.wojewodztwo_napis
        ,a.rok
    from tab_bezrobocie a
)
;quit;

/*
-------------------------------------------------------------------------------------------------
Finalny zbiór danych
-------------------------------------------------------------------------------------------------
*/

proc sql;
create table tab_finalny_zbior_danych as
select
    a.*
    ,b.przecietne_wynagrodzenie
    ,c.stopa_bezrobocia
from tab_podstawowe_dane a
left join tab_wynagrodzenia b on a.wojewodztwo_napis = b.wojewodztwo_napis and a.rok = b.rok
left join tab_bezrobocie c on a.wojewodztwo_napis = c.wojewodztwo_napis and a.rok = c.rok
;quit;