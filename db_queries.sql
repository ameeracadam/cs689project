-- create a view to include both insurance and poverty
-- this is used to answer the business question (2) What impact does enomonic background have on influenza vaccination rate
CREATE VIEW combined_vaccine_coverage_view AS
WITH aggregated_insurance AS (
  SELECT 
    vaccine.cleaned_vaccine,
    dose.dose,
    vcf.vaccine_cumulative_estimate_pct AS vaccine_coverage_insurance,
    insurance.insurance_coverage AS insurance,
    geography.original_geography AS geography
  FROM vaccine_cumulative_fact vcf
  JOIN vaccine_dim vaccine ON vaccine.vaccine_id = vcf.vaccine_cumulative_vaccine_id
  JOIN insurance_dim insurance ON insurance.insurance_id = vcf.vaccine_cumulative_insurance_id
  JOIN geography_dim geography ON geography.geography_id = vcf.vaccine_cumulative_geography_id
  JOIN dose_dim dose ON dose.dose_id = vcf.vaccine_cumulative_dose_id
),
aggregated_poverty AS (
  SELECT 
    vaccine.cleaned_vaccine,
    dose.dose,
    vcf.vaccine_cumulative_estimate_pct AS vaccine_coverage_poverty,
    poverty.poverty_status AS poverty,
    geography.original_geography AS geography
  FROM vaccine_cumulative_fact vcf
  JOIN vaccine_dim vaccine ON vaccine.vaccine_id = vcf.vaccine_cumulative_vaccine_id
  JOIN poverty_dim poverty ON poverty.poverty_id = vcf.vaccine_cumulative_poverty_id
  JOIN geography_dim geography ON geography.geography_id = vcf.vaccine_cumulative_geography_id
  JOIN dose_dim dose ON dose.dose_id = vcf.vaccine_cumulative_dose_id
),
combined_aggregate AS (
  SELECT 
    COALESCE(ai.cleaned_vaccine, ap.cleaned_vaccine) AS cleaned_vaccine,
    COALESCE(ai.dose, ap.dose) AS dose,
    (COALESCE(ai.vaccine_coverage_insurance, 0) + COALESCE(ap.vaccine_coverage_poverty, 0)) /
      (CASE 
         WHEN ai.vaccine_coverage_insurance IS NOT NULL AND ap.vaccine_coverage_poverty IS NOT NULL THEN 2
         ELSE 1
       END) AS average_coverage,
    ai.insurance,
    ap.poverty,
    COALESCE(ai.geography, ap.geography) AS geography
  FROM aggregated_insurance ai
  FULL OUTER JOIN aggregated_poverty ap
    ON ai.cleaned_vaccine = ap.cleaned_vaccine 
       AND ai.dose = ap.dose
       AND ai.geography = ap.geography
)
SELECT * FROM combined_aggregate;

-- SQL Query to answer business question (5)
-- If we were to launch a campaign to increase vaccination rates, which demographic should we prioritise
-- we can get the top3 lowest age group and geography(location) for each vaccine
with aggregated_query as(
select vaccine.cleaned_vaccine,
dose.dose,
vtf.vaccine_transaction_estimate_pct as estimated_vaccine_coverage,
vtf.vaccine_transaction_age as age,
geography.original_geography as geography
from vaccine_transaction_fact vtf
join vaccine_dim vaccine on vaccine.vaccine_id = vtf.vaccine_transaction_vaccine_id
join dose_dim dose on dose.dose_id = vtf.vaccine_transaction_dose_id
join geography_dim geography on geography.geography_id = vtf.vaccine_transaction_geography_id
where geography.original_geography != 'United States' and dose.dose != 'History of disease'
and geography.original_geography not like 'Region%'
),
ranked_demographics as(
select cleaned_vaccine,
age,
geography,
estimated_vaccine_coverage,
dose,
rank() over(partition by cleaned_vaccine order by estimated_vaccine_coverage) as vaccine_rank
from aggregated_query)
select * from ranked_demographics where vaccine_rank <= 3
order by estimated_vaccine_coverage, vaccine_rank, geography

-- getting the average vaccine coverage for each region
WITH aggregated_query AS (
  SELECT 
    vaccine.cleaned_vaccine,
    vcf.vaccine_cumulative_estimate_pct AS estimated_vaccine_coverage,
    geography.region AS region
  FROM vaccine_cumulative_fact vcf
  JOIN vaccine_dim vaccine ON vaccine.vaccine_id = vcf.vaccine_cumulative_vaccine_id
  JOIN geography_dim geography ON geography.geography_id = vcf.vaccine_cumulative_geography_id
  WHERE vaccine_cumulative_overall IS NOT NULL
)
SELECT 
  region,
  cleaned_vaccine,
  AVG(estimated_vaccine_coverage) AS avg_estimated_coverage
FROM aggregated_query
GROUP BY ROLLUP(region, cleaned_vaccine)
ORDER BY region, cleaned_vaccine

-- 
with aggregated_query as(
select vaccine.cleaned_vaccine as vaccine,
dose.dose,
vtf.vaccine_transaction_estimate_pct as estimated_vaccine_coverage,
vtf.vaccine_transaction_age as age_group,
geography.original_geography as geography
from vaccine_transaction_fact vtf
join vaccine_dim vaccine on vtf.vaccine_transaction_vaccine_id = vaccine.vaccine_id
join geography_dim geography on vtf.vaccine_transaction_geography_id = geography.geography_id
join dose_dim dose on vtf.vaccine_transaction_dose_id = dose.dose_id),
ranked_demographics as (
select vaccine,
age_group,
geography,
dose,
estimated_vaccine_coverage,
dense_rank() over(partition by vaccine order by estimated_vaccine_coverage) as vaccine_rank
from aggregated_query)
select * from ranked_demographics
where vaccine_rank <= 3
order by estimated_vaccine_coverage, vaccine, geography;


-- This can help us answer question(4)
-- How does vaccination coverage within each demographic group future disease trends
-- getting the average flu vaccination rate by state and age group, rolled up
-- we can view infer future disease trends for each state and each age group
WITH aggregated_query AS (
  SELECT
    vaccine.cleaned_vaccine,
    icf.age AS age,
    geography.state_territory AS geography,
    icf.influenza_cumulative_estimate_pct AS estimated_vaccine_coverage
  FROM influenza_cumulative_fact icf
  JOIN vaccine_dim vaccine 
    ON vaccine.vaccine_id = icf.influenza_cumulative_vaccine_id
  JOIN geography_dim geography 
    ON geography.geography_id = icf.influenza_cumulative_geography_id
  WHERE 
    icf.influenza_cumulative_estimate_pct != 'NaN'
    AND vaccine.cleaned_vaccine = 'Influenza'
)

  SELECT 
    cleaned_vaccine,
    age,
    geography,
    AVG(estimated_vaccine_coverage) AS average_coverage
  FROM aggregated_query
  GROUP BY rollup(geography, cleaned_vaccine, age)
  ORDER BY 
  geography NULLS LAST,
  cleaned_vaccine NULLS LAST,
  age NULLS LAST