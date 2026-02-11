-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT p1.npi,CONCAT(nppes_provider_first_name,' ',nppes_provider_mi,'. ',nppes_provider_last_org_name) AS name, SUM(total_claim_count) AS claims
FROM prescriber AS p1
LEFT JOIN prescription AS p2
	ON p1.npi = p2.npi
WHERE total_claim_count IS NOT NULL
GROUP BY name,p1.npi
ORDER BY claims DESC;

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT p1.npi, total_claim_count, specialty_description,CONCAT(nppes_provider_first_name,' ',nppes_provider_mi,'. ',nppes_provider_last_org_name) AS name
FROM prescriber AS p1
LEFT JOIN prescription AS p2
	ON p1.npi = p2.npi
WHERE total_claim_count IS NOT NULL
ORDER BY total_claim_count DESC
LIMIT 100;

-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT SUM(total_claim_count) AS total_claims, specialty_description
FROM prescriber AS p1
LEFT JOIN prescription AS p2
	ON p1.npi = p2.npi
WHERE total_claim_count IS NOT NULL
GROUP BY specialty_description
ORDER BY total_claims DESC;

-- b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, sum(total_claim_count)
FROM prescription
INNER JOIN prescriber
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY sum DESC;
-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description, COUNT(prescription.*) AS total_prescriptions
FROM prescriber
FULL JOIN prescription
USING (npi)
GROUP BY specialty_description
HAVING COUNT(prescription.*) = 0;




-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
-- Not sure on this one chief, check w/ instructor
SELECT specialty_description, (COUNT(CASE WHEN opioid_drug_flag='Y' THEN total_claim_count END)/sum(total_claim_count)*100.0) AS percentage
FROM prescription
INNER JOIN prescriber
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY percentage DESC;




-- 3. a. Which drug (generic_name) had the highest total drug cost?
SELECT d1.generic_name, sum(total_drug_cost)::money AS drug_cost
FROM prescription AS p1
LEFT JOIN drug AS d1
    ON p1.drug_name = d1.drug_name
WHERE total_drug_cost IS NOT NULL
GROUP BY d1.generic_name
ORDER BY drug_cost DESC;

-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT 
    d.generic_name,
    (ROUND(SUM(p.total_drug_cost) / SUM(p.total_day_supply), 2))::money AS cost_per_day
FROM prescription p
JOIN drug AS d 
	ON p.drug_name = d.drug_name
WHERE p.total_day_supply > 0
GROUP BY d.generic_name
ORDER BY cost_per_day DESC
LIMIT 100;

-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
	END AS drug_type
FROM drug
ORDER BY drug_type;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT sum(total_drug_cost)::MONEY AS total_cost,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
		END AS drug_type
FROM drug
LEFT JOIN prescription AS p1
	USING(drug_name)
GROUP BY drug_type;

-- 5. a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
WHERE state LIKE '%TN%';

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsa,cbsaname, sum(population) AS total_pop
FROM cbsa
LEFT JOIN population AS p1
	ON cbsa.fipscounty = p1.fipscounty
WHERE population IS NOT NULL
GROUP BY cbsa,cbsaname
ORDER BY total_pop DESC;

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT CONCAT(county,', ',state)AS county,population AS total_pop, cbsa
FROM population
LEFT JOIN cbsa
	ON population.fipscounty = cbsa.fipscounty
LEFT JOIN fips_county AS f1
	ON population.fipscounty = f1.fipscounty
WHERE cbsa IS NULL
ORDER BY population DESC;

-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name,total_claim_count
FROM prescription
WHERE total_claim_count > 3000;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT prescription.drug_name,total_claim_count,
	CASE WHEN opioid_drug_flag ='Y' THEN 'opioid'
	ELSE ''
	END AS is_opioid
FROM prescription
LEFT JOIN drug
	ON prescription.drug_name = drug.drug_name
WHERE total_claim_count > 3000;

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT prescription.drug_name,
	total_claim_count,
	CASE WHEN opioid_drug_flag ='Y' THEN 'opioid'
	ELSE ''
	END AS is_opioid,
	prescriber.nppes_provider_first_name AS first_name,
	prescriber.nppes_provider_last_org_name
FROM prescription
LEFT JOIN drug
	ON prescription.drug_name = drug.drug_name
LEFT JOIN prescriber
	ON prescription.npi = prescriber.npi
WHERE total_claim_count > 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi,drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT npi, drug_name, COALESCE(total_claim_count, 0) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi,drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY total_claims DESC;

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT npi, drug_name, COALESCE(total_claim_count, 0) as total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
	USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY total_claims DESC;