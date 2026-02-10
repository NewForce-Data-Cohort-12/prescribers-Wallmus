-- Write a query which returns the total number of claims for these two groups. Your output should look like this:
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
	ON prescriber.npi = prescription.npi
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY specialty_description;

-- Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:
SELECT 'All Pain Management' AS specialty_description, 
       SUM(total_claims) AS total_claims
FROM (
    SELECT SUM(total_claim_count) AS total_claims
    FROM prescriber
    LEFT JOIN prescription
        ON prescriber.npi = prescription.npi
    WHERE specialty_description = 'Interventional Pain Management'
    UNION ALL 
    SELECT SUM(total_claim_count) AS total_claims
    FROM prescriber
    LEFT JOIN prescription
        ON prescriber.npi = prescription.npi
    WHERE specialty_description = 'Pain Management');

-- Now, instead of using UNION, make use of GROUPING SETS (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output.
SELECT 'All Pain Management' AS specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
    ON prescriber.npi = prescription.npi
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (());

