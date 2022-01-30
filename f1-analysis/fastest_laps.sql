with constructors as
  (select s."constructorId",
          nationality,
          name
   from f1.constructors s),
     constructor_standings as
  (select distinct s."constructorId", --S."raceId",
 sum(wins) all_time_wins
   from f1.constructor_standings s
   where 1=1
     and wins=1 /* this will return the winner only, since there can only be 1 winner per race */
   group by s."constructorId"
   order by 2 desc),
     fastest_laps as
  (select r."constructorId",
          sum(case
                  when rank = '1' then 1
                  else 0
              end) all_time_fastest_laps
   from f1.results r
   where 1=1
   group by r."constructorId"
   order by 2 desc),
     all_time_races as
  (select s."constructorId",
          s."raceId"
   from f1.constructor_results s),
     median_pit_stops_per_driver as
  (select p."driverId",
     (select percentile_disc(0.5) within group(
                                               order by stop)) median_pit_stops_per_driver
   from f1.pit_stops p
   group by p."driverId"),
     median_pit_stops_per_constructor as
  (select c."constructorId",
     (select percentile_disc(0.5) within group(
                                               order by stop)) median_pit_stops_per_constructor
   from f1.pit_stops p
   join f1.constructor_results c on c."raceId" = p."raceId"
   group by c."constructorId"),
   median_qualifying_per_constructor as
  (select p."constructorId",
     (select percentile_disc(0.5) within group(
                                               order by position)) median_qualifying_per_constructor
   from f1.qualifying p
   group by p."constructorId"
  ),
  seasons_per_team AS
	(
	select  
	v."constructorId",
	count(distinct s.year) num_of_seasons_per_team
	from f1.races r
	join f1.seasons s ON s."year" = r."year"
	left join f1.constructor_standings v ON v."raceId" = r."raceId"
	group by v."constructorId"
	),
	average_qualifying_position_per_team AS
	(
	Select r."constructorId", round(AVG(grid),0) avg_qualifying_position
		from f1.results r
		where 1=1
		group by r."constructorId"
	)
select a.name,
       a.nationality,
	   avg_qualifying_position,
	   coalesce(s.num_of_seasons_per_team, 0) num_of_seasons_per_team,
       coalesce(c.all_time_fastest_laps, 0) all_time_fastest_laps,
       coalesce(b.all_time_wins, 0) all_time_wins,
	   coalesce(pc."median_pit_stops_per_constructor", 0) median_pit_stops_per_constructor,
	   coalesce(q."median_qualifying_per_constructor" ,0) median_qualifying_per_constructor,
       count(distinct f."raceId") all_time_races,
       coalesce(round(b.all_time_wins / count(distinct f."raceId"), 2), 0) wins_to_races_ratio
from constructors a
left join constructor_standings b on b."constructorId" = a."constructorId"
left join fastest_laps c on c."constructorId" = a."constructorId"
left join all_time_races f on f."constructorId" = a."constructorId"
left join median_pit_stops_per_constructor pc ON pc."constructorId" = a."constructorId"
left join median_qualifying_per_constructor q ON q."constructorId" = a."constructorId"
left join seasons_per_team s ON s."constructorId" = a."constructorId"
left join average_qualifying_position_per_team t ON t."constructorId" = a."constructorId"
where 1=1
group by a.name,
         a.nationality,
		 avg_qualifying_position,
		 s.num_of_seasons_per_team,
         c.all_time_fastest_laps,
         b.all_time_wins,
		 pc.median_pit_stops_per_constructor,
		 q.median_qualifying_per_constructor
order by 9 desc ;
