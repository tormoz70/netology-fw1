-- "Загрузка данных..."

\copy netlogfw1.films FROM 'data/films.csv' DELIMITER ';' CSV HEADER 

\copy netlogfw1.theatres FROM 'data/holdings.csv' DELIMITER ';' CSV HEADER 

\copy netlogfw1.theatres FROM 'data/theatres.csv' DELIMITER ';' CSV HEADER 

\copy netlogfw1.halls FROM 'data/halls.csv' DELIMITER ';' CSV HEADER 

\copy netlogfw1.sessions FROM 'data/sessions.csv' DELIMITER ';' CSV HEADER 

-- "Данные загружены"
