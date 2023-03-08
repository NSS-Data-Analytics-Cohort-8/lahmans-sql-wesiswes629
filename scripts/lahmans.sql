-- 1. What range of years for baseball games played does the provided database cover? 

SELECT MIN(yearid), MAX(yearid)
FROM teams;

-- ANSWER: 1871 to 2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT p.namegiven, p.height, t.name,
	 COUNT(G_all) AS total_games
FROM people AS p
INNER JOIN appearances AS a
USING (playerID)
LEFT JOIN teams AS t
ON a.teamid = t.teamid AND a.yearid = t.yearid
WHERE height IN (
	SELECT MIN(height)
	FROM people)
GROUP BY p.namegiven, p.height, t.name;


	 
-- ANSWER: Edward Carl was 43 inches tall. He played 1 game for the St Louis Browns.


-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

			
SELECT p.namefirst, p.namelast, SUM(s.salary) :: NUMERIC :: MONEY AS total_salary
FROM people AS p
LEFT JOIN salaries AS s
USING (playerID)
WHERE playerID IN (
	SELECT playerID
	FROM collegeplaying
		WHERE schoolID IN 
			(SELECT schoolID
			FROM schools
			WHERE schoolname LIKE 'Vanderbilt%'))
GROUP BY p.namefirst, p.namelast
ORDER BY total_salary DESC;

-- Answer: There are 24 players from 'Vandy', but only 15 made it to the Majors. David Price has the highest total salary with $81,851,296.00.

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT 
CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos = '2B' OR pos = '1B' OR pos = '3B' OR pos = 'SS' THEN 'Infield'
	ELSE 'Battery' END AS position,
	SUM(po) AS total_putout
FROM fielding
WHERE yearid = 2016
GROUP BY position;


-- Answer: "Battery" 41424 "Infield" 58934 "Outfield" 29560
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

WITH batting AS (
SELECT (yearID/10 * 10) AS decade, (SUM(so) :: NUMERIC) AS so_year, (SUM(hr) :: NUMERIC) AS hr_year
FROM batting AS b
GROUP BY yearID),
	games AS (
SELECT (yearID/10 * 10) AS decade, ((SUM(g)/2) :: NUMERIC) AS games_year
FROM teams AS t
GROUP BY yearID)
SELECT decade, ROUND(AVG(so_year/games_year),2) AS so_per_game,
		ROUND(AVG(hr_year/games_year),2) AS hr_per_game
FROM games AS g
INNER JOIN batting AS b
USING (decade)
WHERE decade >= 1920
GROUP BY decade
ORDER BY decade DESC;

SELECT (yearID/10 * 10) AS decade, ROUND(AVG(so),2) AS avg_so, ROUND(AVG(hr),2) AS avg_hr
FROM batting	
WHERE yearid >=1920
GROUP BY decade
ORDER BY decade;																		

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

-- SELECT playerID, sb, cs, (sb+cs) AS stolen_attempts
-- FROM batting
-- WHERE yearID = 2016
-- AND (sb+cs) > 19;

-- SELECT playerID, SUM(sb), SUM(cs), (SUM(sb)+SUM(cs)) AS stolen_attempts,
-- FROM batting
-- WHERE yearID = 2016
-- GROUP BY playerID
-- 	HAVING (SUM(sb)+SUM(cs)) > 19
-- ORDER BY stolen_attempts DESC;

-- SELECT playerID, SUM(sb) AS total_stolen, SUM(cs) AS total_caught, (SUM(sb)+SUM(cs)) AS total_attempts,
-- 	ROUND(((SUM(sb)::NUMERIC)/((SUM(sb)+SUM(cs))::NUMERIC)),4) AS success_sb_perc
-- FROM batting
-- WHERE yearID = 2016
-- GROUP BY playerID
-- 	HAVING (SUM(sb)+SUM(cs)) > 19
-- ORDER BY success_sb_perc DESC;

WITH sbpercs AS (
SELECT playerID, SUM(sb) AS total_stolen, SUM(cs) AS total_caught, (SUM(sb)+SUM(cs)) AS total_attempts,
	ROUND(((SUM(sb)::NUMERIC)/((SUM(sb)+SUM(cs))::NUMERIC)),4) AS success_sb_perc
FROM batting
WHERE yearID = 2016
GROUP BY playerID
	HAVING (SUM(sb)+SUM(cs)) > 19
ORDER BY success_sb_perc DESC)
SELECT p.namefirst, p.namelast, total_stolen, total_caught, total_attempts, success_sb_perc
FROM sbpercs
LEFT JOIN people AS p
USING (playerID)
ORDER BY success_sb_perc DESC;

-- ANSWER: Chris Owings had 91.3% success rate.

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT yearid, name, w
FROM teams
WHERE yearid > 1969 AND wswin ='N'
ORDER BY w DESC
LIMIT 1;

SELECT yearid, name, w
FROM teams
WHERE yearid > 1969
AND wswin = 'Y'
ORDER BY w
LIMIT 1;

SELECT yearid, name, w
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 
AND yearid <> 1981
AND wswin = 'Y'
ORDER BY w
LIMIT 1;

SELECT yearid, teamid, w, wswin
FROM teams
WHERE yearid > 1969
ORDER BY yearid, w DESC;

WITH maxwins AS (
	SELECT yearid, MAX(w) AS mostwins
	FROM teams
	GROUP BY yearid)
	
SELECT t.yearid, t.name, mostwins, t.wswin
FROM teams AS t
LEFT JOIN maxwins AS m
ON t.yearid = m.yearid AND t.w = m.mostwins
WHERE t.yearid > 1969 
AND m.mostwins IS NOT NULL
AND wswin IS NOT NULL
ORDER BY t.yearid;

WITH maxwins AS (
	SELECT yearid, MAX(w) AS mostwins
	FROM teams
	GROUP BY yearid)
	
	
SELECT t.yearid, t.name, mostwins, t.wswin,
CASE WHEN wswin = 'Y' THEN 1 ELSE 0 END
FROM teams AS t
LEFT JOIN maxwins AS m
ON t.yearid = m.yearid AND t.w = m.mostwins
WHERE t.yearid > 1969 
AND m.mostwins IS NOT NULL
AND wswin IS NOT NULL
ORDER BY t.yearid;

WITH maxwins AS (
	SELECT yearid, MAX(w) AS mostwins
	FROM teams
	GROUP BY yearid)
		
SELECT t.yearid, t.name, mostwins, t.wswin,
	ROUND((SUM(CASE WHEN wswin = 'Y' THEN 1 ELSE 0 END) OVER ()/ COUNT(t.yearid) OVER()::NUMERIC),5)*100 AS perc_wsw_win
FROM teams AS t
LEFT JOIN maxwins AS m
ON t.yearid = m.yearid AND t.w = m.mostwins
WHERE t.yearid > 1969 
AND m.mostwins IS NOT NULL
AND wswin IS NOT NULL
ORDER BY t.yearid;

-- Answer: Most wins but no World Series is the 2001 Seatle Mariners. First it's 1981 LA Dodgers with 63, but after omitting 1981, the least Wins but still won World Series is the 2006 St Louis Cardnials. There is a 23% chance to win for the most wins.

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

-- SELECT team, park
-- FROM homegames
-- WHERE year = 2016;

-- SELECT h.team, p.park_name
-- FROM homegames AS h
-- LEFT JOIN parks AS p
-- USING (park)
-- WHERE year = 2016;

-- SELECT p.park_name, h.team, t.name, (h.attendance/h.games) AS avg_attendance
-- FROM homegames AS h
-- LEFT JOIN parks AS p
-- USING (park)
-- LEFT JOIN teams AS t
-- ON h.team = t.teamid
-- WHERE year = 2016
-- AND h.games > 10
-- ORDER BY avg_attendance DESC
-- LIMIT 5;

-- SELECT p.park_name, (h.attendance/h.games) AS avg_attendance
-- FROM homegames AS h
-- LEFT JOIN parks AS p
-- USING (park)
-- WHERE year = 2016
-- AND h.games > 10
-- ORDER BY avg_attendance DESC
-- LIMIT 5;

-- SELECT p.park_name, (h.attendance/h.games) AS avg_attendance
-- FROM homegames AS h
-- LEFT JOIN parks AS p
-- ON h.park = p.park
-- WHERE year = 2016
-- AND h.games > 10
-- ORDER BY avg_attendance DESC
-- LIMIT 5;

-- SELECT p.park_name, p.park, (h.attendance/h.games) AS avg_attendance
-- FROM homegames AS h
-- LEFT JOIN parks AS p
-- ON h.park = p.park
-- WHERE year = 2016
-- AND h.games > 10
-- ORDER BY avg_attendance DESC
-- LIMIT 5;

WITH hometeam AS (SELECT h.team, t.name AS teamname, h.park
FROM homegames AS h
LEFT JOIN teams AS t
ON h.year = t.yearid and h.team = t.teamid
WHERE h.year = 2016),
	ballpark AS (SELECT p.park_name, p.park, (h.attendance/h.games) AS avg_attendance
FROM homegames AS h
LEFT JOIN parks AS p
ON h.park = p.park
WHERE year = 2016
AND h.games > 10)

SELECT teamname, ballpark.park_name, avg_attendance
FROM hometeam
INNER JOIN ballpark
ON hometeam.park = ballpark.park
ORDER BY avg_attendance DESC
LIMIT 5;

WITH hometeam AS (SELECT h.team, t.name AS teamname, h.park
FROM homegames AS h
LEFT JOIN teams AS t
ON h.year = t.yearid and h.team = t.teamid
WHERE h.year = 2016),
	ballpark AS (SELECT p.park_name, p.park, (h.attendance/h.games) AS avg_attendance
FROM homegames AS h
LEFT JOIN parks AS p
ON h.park = p.park
WHERE year = 2016
AND h.games > 10)

SELECT teamname, ballpark.park_name, avg_attendance
FROM hometeam
INNER JOIN ballpark
ON hometeam.park = ballpark.park
ORDER BY avg_attendance 
LIMIT 5;

-- Answer: Top 5 "Los Angeles Dodgers"	"Dodger Stadium"	45719 "St. Louis Cardinals"	"Busch Stadium III"	42524 "Toronto Blue Jays"	"Rogers Centre"	41877 "San Francisco Giants"	"AT&T Park"	41546 "Chicago Cubs"	"Wrigley Field"	39906
-- Answer: Lowest 5 "Tampa Bay Rays"	"Tropicana Field"	15878 "Oakland Athletics"	"Oakland-Alameda County Coliseum"	18784 "Cleveland Indians"	"Progressive Field"	19650 "Miami Marlins"	"Marlins Park"	21405 "Chicago White Sox"	"U.S. Cellular Field"	21559

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT *
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year';

SELECT playerid, yearid
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year'
AND lgid = 'NL';

SELECT playerid, yearid
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year'
AND lgid = 'AL';

WITH tsnaward AS (SELECT playerid, yearid, lgid
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year'
AND lgid = 'AL'
UNION 
SELECT playerid, yearid, lgid
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year'
AND lgid = 'NL')

SELECT p.namefirst, p.namelast, tsnaward.yearid, m.teamid, m.lgid
FROM tsnaward 
INNER JOIN people AS p
USING (playerid)
LEFT JOIN managers AS m
USING (playerid, yearid)
ORDER BY p.namelast;

WITH tsnaward AS (SELECT playerid
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
	AND lgid = 'AL'
INTERSECT 
	SELECT playerid
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
	AND lgid = 'NL')

SELECT tsnaward.playerid, p.namefirst, p.namelast, m.yearid, m.teamid, m.lgid
FROM tsnaward 
INNER JOIN people AS p
USING (playerid)
LEFT JOIN managers AS m
USING (playerid)
ORDER BY p.namelast;

SELECT p.namefirst, p.namelast, m.yearid, m.lgid
FROM people AS p
INNER JOIN managers AS m
USING (playerid)
WHERE playerid IN (SELECT playerid 
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
	AND lgid = 'AL'
INTERSECT 
	SELECT playerid 
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
	AND lgid = 'NL');
	

SELECT p.namefirst, p.namelast, m.yearid, m.lgid, m.teamid
FROM (SELECT playerid 
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
	AND lgid = 'AL'
INTERSECT 
	SELECT playerid 
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
	AND lgid = 'NL') AS awards
	INNER JOIN people AS p
	USING (playerid)
INNER JOIN managers AS m
USING (playerid)

SELECT DISTINCT a.yearid, a.playerid, p.namefirst, p.namelast, t.name, a.lgid
FROM people AS p
LEFT JOIN awardsmanagers AS a
USING (playerid)
LEFT JOIN managers AS m
ON m.yearid = a.yearid
AND m.playerid = a.playerid
LEFT JOIN teams AS t
ON m.teamid = t.teamid
AND m.yearid = t.yearid
WHERE a.playerid IN 
		(SELECT playerid
		FROM awardsmanagers
		WHERE awardid = 'TSN Manager of the Year'
		AND lgid =  'AL'
		INTERSECT
		SELECT playerid
		FROM awardsmanagers
		WHERE awardid = 'TSN Manager of the Year'
		AND lgid = 'NL');
		
-- Jim Leyland and Davey Johnson both won the award in both leagues.
		
-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


	SELECT playerid, yearid, MAX(hr)
	FROM batting
	GROUP BY playerid, yearid
	HAVING MAX(hr) > 0
	ORDER BY yearid DESC
	
	with maxhr AS (
SELECT playerid, yearid, MAX(hr) AS max
FROM batting
GROUP BY playerid, yearid
HAVING MAX(hr) > 0
ORDER BY yearid)

SELECT namefirst, namelast, yearid, maxhr.max
FROM people
JOIN maxhr
USING (playerid)
WHERE yearid = 2016
AND people.debut :: date < '2006-01-01'
ORDER BY maxhr.max DESC;

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

  
