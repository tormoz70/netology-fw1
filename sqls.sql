SELECT 'ФИО: Халиуллин Айрат'; 


-- "1. Проверяем распределение по партициям"

with databyparts as (
select count(1) cnt from netlogfw1.sessions_201511
union all
select count(1) cnt from netlogfw1.sessions_201512
union all
select count(1) cnt from netlogfw1.sessions_201601
union all
select count(1) cnt from netlogfw1.sessions_201602
union all
select count(1) cnt from netlogfw1.sessions_201603
)
select 'Кол-во записей по партициям' as "Описание", sum(cnt) as "Значение" from databyparts
union all
select 'Кол-во записей по родительской таблице' as "Описание", count(1) as "Значение" from netlogfw1.sessions;

--  "2. Выборка список киносетей"
SELECT
  t.holding_id as "ID киносети",
  h.theatre_name as "Название киносети",
  count(distinct t.theatre_id) as "Кол-во кинотеатров"
FROM netlogfw1.theatres t
	LEFT JOIN netlogfw1.theatres h ON h.theatre_id = t.holding_id
WHERE t.orgtype = 'p'
GROUP BY t.holding_id, h.theatre_name
;

--  "3. Выборка список кинотеатров, первые 30 кинотеатров"
SELECT
  t.holding_id as "ID киносети",
  h.theatre_name as "Название киносети",
  t.region as "Регион",
  t.city as "Город",
  t.theatre_id as "ID кинотеатра",
  t.theatre_name as "Название кинотеатра"
FROM netlogfw1.theatres t
	LEFT JOIN netlogfw1.theatres h ON h.theatre_id = t.holding_id
WHERE t.orgtype = 'p'
ORDER BY "Название киносети", "Регион", "Город", "Название кинотеатра"
LIMIT 30
;

-- "4. Статистика по оборудованию кинотеатров по регионам"
SELECT t.region as "Регион", 
	count(distinct h.theatre_id) as "Кинотеатров",
	count(distinct h.hall_id) as "Кинозалов",
	count(distinct h.hall_id)/count(distinct h.theatre_id) as "Сред. кинозалов на кинотеатр",
	trunc(avg(h.places)) as "Сред. мест на кинозал",
	sum(case h.exp_3d when '1' then 1 else 0 end) as "Кол-во 3D кинозалов",
	sum(case h.exp_imax when '1' then 1 else 0 end) as "Кол-во IMAX кинозалов",
	sum(case h.exp_laser when '1' then 1 else 0 end) as "Кол-во LASER кинозалов",
	sum(case h.exp_dvd when '1' then 1 else 0 end) as "Кол-во DVD кинозалов"
  FROM netlogfw1.halls h
	INNER JOIN netlogfw1.theatres t ON t.theatre_id = h.theatre_id AND t.orgtype = 'p'
GROUP BY t.region
ORDER BY 2 DESC
;

-- "5. Выборка последних 30 сеансов 2015 года"
WITH vtheatres AS (
	SELECT
	  t.holding_id,
	  h.theatre_name as holding_name,
	  t.theatre_id,
	  t.theatre_name,
	  t.region,
	  t.city
	FROM netlogfw1.theatres t
		LEFT JOIN netlogfw1.theatres h ON h.theatre_id = t.holding_id
	WHERE t.orgtype = 'p'
)
SELECT 
  s.sess_id as "ID сеанса",  
  s.show_date as "Дата/время сеанса",  
  t.region as "Регион",  
  t.city as "Город",  
  t.holding_id as "ID киносети",  
  t.holding_name as "Название киносети",  
  t.theatre_id as "ID кинотеатра",  
  t.theatre_name as "Название кинотеатра",  
  s.hall_id as "ID кинозала",  
  h.hall_name as "Название кинозала",  
  h.places as "Кол-во мест в кинозале",
  s.film_id as "ID фильма",  
  s.tckts as "Кол-во зрителей",
  case when h.places > 0 then round(s.tckts/h.places * 100, 1) else 0 end as "Заполненность зала, %",
  s.summ as "Сборы, руб"
  FROM netlogfw1.sessions s
  INNER JOIN vtheatres t ON t.theatre_id = s.theatre_id
  INNER JOIN netlogfw1.halls h ON h.hall_id = s.hall_id
  WHERE s.show_date BETWEEN to_timestamp('2015-12-31T00:00:00', 'YYYY-MM-DD"T"HH24:MI:SS') AND to_timestamp('2015-12-31T23:59:59', 'YYYY-MM-DD"T"HH24:MI:SS')
 ORDER BY show_date DESC
 LIMIT 30
;

-- "6. Топ 10 фильмов по сборам за весь период"
WITH sumdata AS (
	SELECT 
	  s.film_id,  
	  sum(s.summ) as summ
	  FROM netlogfw1.sessions s
	 GROUP BY s.film_id
)
SELECT a.film_id as "Номер ПУ", 
	a.film_name as "Название фильма", 
	a.prod_year as "Год создания", 
	a.mdirector as "Режисер", 
	to_char(a.startdate, 'DD.MM.YYYY') as "Дата выхода в прокат",
	to_char(s.summ, 'FM999G999G990D0') as "Сумма сборов, руб"
  FROM netlogfw1.films a
  INNER JOIN sumdata s ON s.film_id = a.film_id
  ORDER BY summ DESC
   LIMIT 10
;

-- "7. Как фильм 121024915 - "Звёздные войны: Пробуждение силы", набирал зрителей в течении первых 30 дней проката"
WITH filmstat AS (
	SELECT 
	  s.film_id,  
	  date_trunc('day', s.show_date)::date as show_date,
	  sum(s.tckts) as tckts
	  FROM netlogfw1.sessions s
	 GROUP BY s.film_id, date_trunc('day', s.show_date)::date
)
SELECT
	a.show_date as "Дата показа",
	case EXTRACT(DOW FROM a.show_date) 
		when 0 then 'ВС' when 1 then 'ПН' when 2 then 'ВТ' when 3 then 'СР' 
		when 4 then 'ЧТ' when 5 then 'ПТ' when 6 then 'СБ' 
	end as dayw,
	a.tckts as "Зрителей",
	round(case when coalesce(lag(a.tckts, 1) over (order by a.show_date), 0) = 0 
			then 100 else (a.tckts/coalesce(lag(a.tckts, 1) over (order by a.show_date), 0) - 1) * 100 end, 1) as "Прирост зрителей, %" -- Прирост зрителей по отношению к предыдущему дню
FROM filmstat a
WHERE a.film_id = '121024915'
ORDER BY a.show_date
LIMIT 30
;


-- "8. Сравнение проката по кинотеатрам, топ 10 скинотеатров со схожим репертуаром в период новогодних праздинков с 2015-12-30 по 2016-01-11"
WITH theatres AS (
	SELECT a.theatre_id, a.theatre_name
	FROM netlogfw1.theatres a
	WHERE a.orgtype = 'p'
)
,hldpairs AS (
	SELECT a.theatre_id as theatre1_id, a.theatre_name as theatre1_name, b.theatre_id as theatre2_id, b.theatre_name as theatre2_name,
	(SELECT string_agg(to_char(aa.itm, 'FM9999999'), '-') FROM (SELECT unnest(ARRAY[a.theatre_id, b.theatre_id]) as itm ORDER BY 1) aa) as pairkey -- отсортированный список идентификаторов сравниваемых сетей
	FROM theatres a
		CROSS JOIN theatres b 
	WHERE a.theatre_id != b.theatre_id
)
,hldpairsuq AS ( -- исключаем дублирующиеся пары
SELECT theatre1_id, theatre1_name, theatre2_id, theatre2_name FROM (
	SELECT a.*,
		row_number() over (partition by pairkey) pnum
	  FROM hldpairs a
	) aa WHERE pnum = 1
)
,theatrefilms AS (
	SELECT 
	  s.theatre_id, array_agg(distinct s.film_id) afilms
	  FROM netlogfw1.sessions s
	 WHERE s.show_date BETWEEN to_timestamp('2015-12-30T00:00:00', 'YYYY-MM-DD"T"HH24:MI:SS') AND to_timestamp('2016-01-11T23:59:59', 'YYYY-MM-DD"T"HH24:MI:SS')
	 GROUP BY s.theatre_id
)
,tfintersects AS (
	SELECT 
		theatre1_id, 
		theatre1_name, 
		theatre2_id, 
		theatre2_name,
		(select array_agg(arrItem) as intersectItems from 
		   (
			select UNNEST(f1.afilms) as arrItem
			intersect 
			select UNNEST(f2.afilms) as arrItem
		   ) cmn) as intersects
	  FROM hldpairsuq a
		INNER JOIN theatrefilms f1 ON f1.theatre_id = a.theatre1_id
		INNER JOIN theatrefilms f2 ON f2.theatre_id = a.theatre2_id
)
SELECT 
	a.theatre1_id as "ID кинотеатра 1", 
	a.theatre1_name as "Название кинотеатра 1", 
	a.theatre2_id as "ID кинотеатра 2", 
	a.theatre2_name as "Название кинотеатра 3",
	array_length(a.intersects, 1) as "Кол-во собпадающих фильмов"
FROM tfintersects a
ORDER BY "Кол-во собпадающих фильмов" DESC
LIMIT 10
;


-- "9. Сравнение жанров по популярности в период новогодних праздников 2016 года"
WITH vfilms AS (
	select a.film_id,
		trim(unnest(string_to_array(a.genre, ','))) as genre
	from netlogfw1.films a
)
SELECT 
  f.genre as "Жанр", 
  sum(s.tckts) as "Кол-во зрителей"
  FROM netlogfw1.sessions s
	INNER JOIN vfilms f ON f.film_id = s.film_id
 WHERE s.show_date BETWEEN to_timestamp('2015-12-30T00:00:00', 'YYYY-MM-DD"T"HH24:MI:SS') AND to_timestamp('2016-01-11T23:59:59', 'YYYY-MM-DD"T"HH24:MI:SS')
 GROUP BY f.genre
ORDER BY 2 DESC;

-- "10. Самые посещаемые кинотеатры по регионам в период новогодних праздников 2016 года"
WITH 
theatres AS (
SELECT
  t.holding_id,
  h.theatre_name as holding_name,
  t.theatre_id,
  t.theatre_name,
  t.region,
  t.city
FROM netlogfw1.theatres t
	LEFT JOIN netlogfw1.theatres h ON h.theatre_id = t.holding_id
WHERE t.orgtype = 'p'
)
,theatretckts AS (
	SELECT 
	  t.region,
	  t.city,
	  t.holding_name,
	  s.theatre_id, 
	  t.theatre_name,
	  sum(s.tckts) as tckts,
	  row_number() over (PARTITION BY t.region ORDER BY sum(s.tckts) DESC) npos
	  FROM netlogfw1.sessions s
		INNER JOIN theatres t	ON t.theatre_id = s.theatre_id 
	 WHERE s.show_date BETWEEN to_timestamp('2015-12-30T00:00:00', 'YYYY-MM-DD"T"HH24:MI:SS') AND to_timestamp('2016-01-11T23:59:59', 'YYYY-MM-DD"T"HH24:MI:SS')
	 GROUP BY t.region, t.city, t.holding_name, s.theatre_id, t.theatre_name
)
select 
	a.region as "Регион",
	a.city as "Город",
	a.holding_name as "Киносеть",
	a.theatre_name as "Кинотеатр",
	a.tckts as "Всего зрителей"
from theatretckts a
where a.npos = 1;
