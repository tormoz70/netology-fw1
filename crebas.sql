-- "Инициализация базы данных"


-- "1. Удаляем схему"
DROP SCHEMA IF EXISTS netlogfw1 CASCADE;

-- "2. Создаем схему"
CREATE SCHEMA netlogfw1;

-- "3. Создаем таблицу КИНОТЕАТРЫ"
CREATE TABLE netlogfw1.theatres (
    theatre_id                     NUMERIC(18) NOT NULL,
    theatre_name                   TEXT NOT NULL,
    orgtype                        CHAR(1) NOT NULL,
    holding_id                     NUMERIC(18),
    region                         TEXT NOT NULL,
    city                           TEXT NOT NULL,
    CONSTRAINT pk_theatres PRIMARY KEY (theatre_id),
    CONSTRAINT fk_theatres_holding FOREIGN KEY (holding_id)
      REFERENCES netlogfw1.theatres (theatre_id)
);


-- "4. Создаем таблицу КИНОЗАЛЫ"
CREATE TABLE netlogfw1.halls (
    hall_id                        NUMERIC(18) NOT NULL,
    theatre_id                     NUMERIC(18) NOT NULL,
    hall_name                      TEXT NOT NULL,
    places                         NUMERIC(10) NOT NULL,
    exp_3d                         CHAR(1) NOT NULL DEFAULT '0',
    exp_imax                       CHAR(1) NOT NULL DEFAULT '0',
    exp_laser                       CHAR(1) NOT NULL DEFAULT '0',
    exp_dvd                        CHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT pk_halls PRIMARY KEY (hall_id),
    CONSTRAINT fk_halls_theatre FOREIGN KEY (theatre_id)
      REFERENCES netlogfw1.theatres (theatre_id),
    CONSTRAINT ckc_3d_halls CHECK (exp_3d IN ('0', '1')),
    CONSTRAINT ckc_imax_halls CHECK (exp_3d IN ('0', '1')),
    CONSTRAINT ckc_laser_halls CHECK (exp_3d IN ('0', '1')),
    CONSTRAINT ckc_dvd_halls CHECK (exp_3d IN ('0', '1'))
);

CREATE INDEX halls_theatre_fk ON netlogfw1.halls (theatre_id);

-- "5. Создаем таблицу РЕЕСТР ФИЛЬМОВ"
CREATE TABLE netlogfw1.films (
    film_id                        VARCHAR(20) NOT NULL,
    film_name                      VARCHAR(500) NOT NULL,
    prod_year                      VARCHAR(300),
    madein                         VARCHAR(500),
    studia                         TEXT,
    startdate                      DATE,
    age_restr                      NUMERIC(4),
    genre                          TEXT,
    mdirector                      TEXT,
    CONSTRAINT pk_films PRIMARY KEY (film_id)
);

-- "6. Создаем таблицу РЕЕСТР СТАТИСТИКА ПО СЕАНСАМ"
CREATE TABLE netlogfw1.sessions (
    sess_id                        NUMERIC(18) NOT NULL,
    show_date                      TIMESTAMP NOT NULL,
    theatre_id                     NUMERIC(18) NOT NULL,
    hall_id                        NUMERIC(18) NOT NULL,
    film_id                        VARCHAR(20) NOT NULL,
    tckts                          NUMERIC NOT NULL DEFAULT 0,
    summ                           NUMERIC NOT NULL DEFAULT 0
);

      
CREATE INDEX sessions_theatre_fk ON netlogfw1.sessions (theatre_id);
CREATE INDEX sessions_hall_fk ON netlogfw1.sessions (hall_id);
CREATE INDEX sessions_film_fk ON netlogfw1.sessions (film_id);

CREATE TABLE netlogfw1.sessions_201511 (
    CHECK (to_char(show_date, 'YYYYMM') = '201511'),
    CONSTRAINT pk_sessions_201511 PRIMARY KEY (sess_id),
    CONSTRAINT fk_sessions_theatre_201511 FOREIGN KEY (theatre_id)
      REFERENCES netlogfw1.theatres (theatre_id),
    CONSTRAINT fk_sessions_hall_201511 FOREIGN KEY (hall_id)
      REFERENCES netlogfw1.halls (hall_id),
    CONSTRAINT fk_sessions_film_201511 FOREIGN KEY (film_id)
      REFERENCES netlogfw1.films (film_id)
) INHERITS (netlogfw1.sessions); 

CREATE TABLE netlogfw1.sessions_201512 (
    CHECK (to_char(show_date, 'YYYYMM') = '201512'),
    CONSTRAINT pk_sessions_201512 PRIMARY KEY (sess_id),
    CONSTRAINT fk_sessions_theatre_201512 FOREIGN KEY (theatre_id)
      REFERENCES netlogfw1.theatres (theatre_id),
    CONSTRAINT fk_sessions_hall_201512 FOREIGN KEY (hall_id)
      REFERENCES netlogfw1.halls (hall_id),
    CONSTRAINT fk_sessions_film_201512 FOREIGN KEY (film_id)
      REFERENCES netlogfw1.films (film_id)
) INHERITS (netlogfw1.sessions); 

CREATE TABLE netlogfw1.sessions_201601 (
    CHECK (to_char(show_date, 'YYYYMM') = '201601'),
    CONSTRAINT pk_sessions_201601 PRIMARY KEY (sess_id),
    CONSTRAINT fk_sessions_theatre_201601 FOREIGN KEY (theatre_id)
      REFERENCES netlogfw1.theatres (theatre_id),
    CONSTRAINT fk_sessions_hall_201601 FOREIGN KEY (hall_id)
      REFERENCES netlogfw1.halls (hall_id),
    CONSTRAINT fk_sessions_film_201601 FOREIGN KEY (film_id)
      REFERENCES netlogfw1.films (film_id)
) INHERITS (netlogfw1.sessions); 

CREATE TABLE netlogfw1.sessions_201602 (
    CHECK (to_char(show_date, 'YYYYMM') = '201602'),
    CONSTRAINT pk_sessions201602 PRIMARY KEY (sess_id),
    CONSTRAINT fk_sessions_theatre201602 FOREIGN KEY (theatre_id)
      REFERENCES netlogfw1.theatres (theatre_id),
    CONSTRAINT fk_sessions_hall201602 FOREIGN KEY (hall_id)
      REFERENCES netlogfw1.halls (hall_id),
    CONSTRAINT fk_sessions_film201602 FOREIGN KEY (film_id)
      REFERENCES netlogfw1.films (film_id)
) INHERITS (netlogfw1.sessions); 

CREATE TABLE netlogfw1.sessions_201603 (
    CHECK (to_char(show_date, 'YYYYMM') = '201603'),
    CONSTRAINT pk_sessions_201603 PRIMARY KEY (sess_id),
    CONSTRAINT fk_sessions_theatre_201603 FOREIGN KEY (theatre_id)
      REFERENCES netlogfw1.theatres (theatre_id),
    CONSTRAINT fk_sessions_hall_201603 FOREIGN KEY (hall_id)
      REFERENCES netlogfw1.halls (hall_id),
    CONSTRAINT fk_sessions_film_201603 FOREIGN KEY (film_id)
      REFERENCES netlogfw1.films (film_id)
) INHERITS (netlogfw1.sessions); 

CREATE OR REPLACE FUNCTION netlogfw1.sessions_insert_trigger()
RETURNS TRIGGER AS $$
DECLARE
	v_partition_name text := 'sessions_'||to_char(NEW.show_date, 'YYYYMM');
BEGIN
	execute 'insert into netlogfw1.'||v_partition_name||' values ($1, $2, $3, $4, $5, $6, $7)'
	using NEW.sess_id, NEW.show_date, NEW.theatre_id, NEW.hall_id, NEW.film_id, NEW.tckts, NEW.summ;
	RETURN NULL;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER insert_sessions_trigger
    BEFORE INSERT ON netlogfw1.sessions
    FOR EACH ROW EXECUTE PROCEDURE netlogfw1.sessions_insert_trigger();

