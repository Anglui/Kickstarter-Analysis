# Convert all units of currency to USD

UPDATE campaign
SET 
	goal = CASE
		WHEN currency_id = 1 THEN 1.25*goal 	#convert GBP to USD
		WHEN currency_id = 3 THEN 0.79*goal		#convert CAD to USD
		WHEN currency_id = 4 THEN 0.71*goal 	#convert AUD to USD
		WHEN currency_id = 5 THEN 0.10*goal 	#convert NOK to USD
		WHEN currency_id = 6 THEN 1.06*goal 	#convert EUR to USD
		WHEN currency_id = 7 THEN 0.051*goal 	#convert MXN to USD
		WHEN currency_id = 8 THEN 0.10*goal		#convert SEK to USD
		WHEN currency_id = 9 THEN 0.64*goal		#convert NZD to USD
		WHEN currency_id = 10 THEN 1.02*goal	#convert CHF to USD
		WHEN currency_id = 11 THEN 0.14*goal	#convert DKK to USD
		WHEN currency_id = 12 THEN 0.13*goal	#convert HKD to USD
		WHEN currency_id = 13 THEN 0.72*goal	#convert SGD to USD
		WHEN currency_id = 14 THEN 0.0074*goal	#convert JPY to USD
		ELSE goal
	END
WHERE currency_id IN(1,3,4,5,6,7,8,9,10,11,12,13,14); 

UPDATE campaign
SET 
	pledged = CASE
		WHEN currency_id = 1 THEN 1.25*pledged 		#convert GBP to USD
		WHEN currency_id = 3 THEN 0.79*pledged		#convert CAD to USD
		WHEN currency_id = 4 THEN 0.71*pledged 		#convert AUD to USD
		WHEN currency_id = 5 THEN 0.10*pledged 		#convert NOK to USD
		WHEN currency_id = 6 THEN 1.06*pledged 		#convert EUR to USD
		WHEN currency_id = 7 THEN 0.051*pledged 	#convert MXN to USD
		WHEN currency_id = 8 THEN 0.10*pledged		#convert SEK to USD
		WHEN currency_id = 9 THEN 0.64*pledged		#convert NZD to USD
		WHEN currency_id = 10 THEN 1.02*pledged		#convert CHF to USD
		WHEN currency_id = 11 THEN 0.14*pledged		#convert DKK to USD
		WHEN currency_id = 12 THEN 0.13*pledged		#convert HKD to USD
		WHEN currency_id = 13 THEN 0.72*pledged		#convert SGD to USD
		WHEN currency_id = 14 THEN 0.0074*pledged	#convert JPY to USD
		ELSE pledged
	END
WHERE currency_id IN(1,3,4,5,6,7,8,9,10,11,12,13,14);

#Clean data
DELETE	#Remove any row that records data for projects are live, canceled, or suspended
FROM campaign
WHERE NOT outcome = 'failed' AND NOT outcome = 'successful';

DELETE	#Remove any row with the country id of 11. 
FROM campaign
WHERE country_id = 11;

#Five-Number Summary for Successful Campaigns
SELECT goal
FROM campaign
WHERE outcome IN('successful')
ORDER BY goal ASC
LIMIT 2656, 2; #Find Median. Replace value with 1328 for q1 and 3984 for q3. Find min-max 1.5*IQR

#Five-Number Summary for Failed Campaigns
SELECT goal
FROM campaign
WHERE outcome IN('failed')
ORDER BY goal ASC
LIMIT 3922, 2; #Find Median. Replace value with 1961 for q1 and 5883 for q3. Find min-max 1.5*IQR


#Generate backers by category
SELECT  c.name as Category, ROUND(SUM(ca.pledged)) AS TotalFundsPledged, SUM(ca.backers) AS TotalBackers
FROM campaign as ca
JOIN sub_category as sc
ON ca.sub_category_id = sc.id
JOIN category as c
ON sc.category_id = c.id
GROUP BY c.name
ORDER BY TotalBackers DESC;

#Generate backers by subcategory
SELECT  sc.name, ROUND(SUM(ca.pledged)) AS TotalFundsPledged, SUM(ca.backers) AS TotalBackers
FROM campaign as ca
JOIN sub_category as sc
ON ca.sub_category_id = sc.id
GROUP BY sc.name
ORDER BY TotalBackers DESC;

#Generate pledged amount by category
SELECT  c.name as Category, ROUND(SUM(ca.pledged)) AS TotalFundsPledged, SUM(ca.backers) AS TotalBackers
FROM campaign as ca
JOIN sub_category as sc
ON ca.sub_category_id = sc.id
JOIN category as c
ON sc.category_id = c.id
GROUP BY c.name
ORDER BY TotalFundsPledged DESC;

#Generate pledged amount by subcategory
SELECT  sc.name, ROUND(SUM(ca.pledged)) AS TotalFundsPledged, SUM(ca.backers) AS TotalBackers
FROM campaign as ca
JOIN sub_category as sc
ON ca.sub_category_id = sc.id
GROUP BY sc.name
ORDER BY TotalFundsPledged DESC;

#Find most successful tabletop campaign 
SELECT name, goal, pledged, backers
FROM campaign
WHERE outcome IN('successful') and sub_category_id = 14 #tabletop subcategory id is 14
ORDER BY pledged DESC;

#Find top 3 countries with successful campaigns in terms of total pledged amount and backers
SELECT co.name as Country, country_id, ROUND(SUM(ca.pledged)) AS TotalFundsPledged, SUM(ca.backers) AS TotalBackers, 
count(*) as SuccessfulCampaigns
FROM campaign as ca
LEFT OUTER JOIN country as co
ON ca.country_id = co.id
WHERE outcome IN('successful')
GROUP BY country_id
ORDER BY TotalFundsPledged DESC; #Replace this with TotalBackers to find top 3 countries in terms of backers

#Campaign time dependence
CREATE TABLE LengthSuccess AS	#Table will be exported to Google Sheets to create graph
SELECT CEIL(DATEDIFF(deadline, launched)/7) as Weeks, count(*) as "Number of Campaigns", 
ROUND(AVG(pledged)) as "Average Pledged per Campaign", FLOOR(AVG(backers)) as "Average Backers per Campaign" 
FROM campaign
WHERE outcome IN('successful')	
GROUP BY Weeks
ORDER BY Weeks ASC;

CREATE TABLE LengthFailed AS 	#Table will be exported and appended to Sheet above
SELECT CEIL(DATEDIFF(deadline, launched)/7) as Weeks, count(*) as "Number of Campaigns", 
ROUND(AVG(pledged)) as "Average Pledged per Campaign", FLOOR(AVG(backers)) as "Average Backers per Campaign" 
FROM campaign
WHERE outcome IN('failed')
GROUP BY Weeks
ORDER BY Weeks ASC;

#Second Look at Backers
CREATE TABLE SuccessfulCampaign AS	#Exported to Google Sheets to create graph
SELECT outcome AS Outcome, id AS "Campaign ID", pledged AS "Pledged Amount", backers as Backers,
ROUND(pledged/backers) AS "Avg Amount Pledged Per Backer"
FROM campaign
WHERE outcome IN('successful');	


CREATE TABLE FailedCampaign AS	#Exported and appended to sheet to create graph
SELECT outcome AS Outcome, id AS "Campaign ID", pledged AS "Pledged Amount", backers as Backers,
ROUND(pledged/backers) AS PledgePerBacker
FROM campaign
WHERE outcome IN('failed');	

UPDATE FailedCampaign
SET PledgePerBacker = 0			#If there are no backers then PledgePerBacker will result in null. 
WHERE PledgePerBacker IS NULL;	#This gives it a value that can be graphed (0). 

#Narrowing in on Tabletop Games subcategory
CREATE TABLE TableTopGames AS	#Creating table solely for successful tabletop games campaigns
SELECT outcome AS Outcome, id AS "Campaign ID", goal as Goal, pledged AS Pledged, backers as Backers
FROM campaign
WHERE outcome IN('successful') and sub_category_id = 14
ORDER BY goal ASC;

SELECT count(*)	#Find how many campaigns had pledged funds of at least 15000
FROM TableTopGames
WHERE Pledged >= 15000;

SELECT ROUND(SUM(Pledged)/SUM(Backers)) #Find average pledge per backer for campaigns where pledged at least 15000
FROM TableTopGames
WHERE Pledged >= 15000;

SELECT COUNT(*)	#Find how many campaigns had a goal of at least 15000 and met that goal
FROM TableTopGames
WHERE Goal >= 15000; #Don't need to specify plege amount since all campaigns listed are successful

SELECT *	#Finding the bottom half of 126 campaigns that raised at least 15000 dollars
FROM TableTopGames
WHERE Pledged >= 15000
ORDER BY Pledged
LIMIT 62,1;

SELECT FLOOR(SUM(Backers)/COUNT(*)) #Average number of backers of bottom half of campaigns from above
FROM TableTopGames
WHERE Pledged >= 15000 AND Pledged <36500;

SELECT ROUND(SUM(Pledged)/SUM(Backers))	#Finding average pledge per backer of campaigns of bottom half
FROM TableTopGames
WHERE Pledged >= 15000 AND Pledged <36500;

SELECT FLOOR(SUM(Backers)/COUNT(*)) #Finding average number of backers of campaigns that raised less than 15000
FROM TableTopGames
WHERE Pledged < 15000;

SELECT ROUND(SUM(Pledged)/SUM(Backers)) #Finding average pledge per backer of said campaigns
FROM TableTopGames
WHERE Pledged < 15000;





