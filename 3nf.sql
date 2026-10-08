/*
===============================================================================
 Вариант 4. Система организации городского спортивного соревнования
 Реализация структуры БД в третьей нормальной форме (3NF), PostgreSQL 14+
===============================================================================

Назначение модели:
- хранение сведений о соревновании, видах спорта и дисциплинах;
- учет площадок и организаций, участвующих в подготовке;
- регистрация спортсменов/команд и формирование заявок на старты;
- построение расписания, назначение судей, фиксация результатов и наград;
- планирование организационных задач и зависимостей между ними.

Скрипт создает схему nf3 в ТЕКУЩЕЙ базе данных.
При необходимости сама база может быть создана администратором отдельно:
    CREATE DATABASE city_sport_competition WITH ENCODING 'UTF8';
После подключения к ней можно выполнять данный скрипт.
*/

BEGIN;

DROP SCHEMA IF EXISTS nf3 CASCADE;
CREATE SCHEMA nf3;
SET search_path = nf3, public;

-- ============================================================================
-- 1. Классификаторы и основные справочники
-- ============================================================================

CREATE TABLE sport (
    sport_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sport_code      varchar(30)  NOT NULL UNIQUE,
    sport_name      varchar(120) NOT NULL UNIQUE
);

COMMENT ON TABLE sport IS 'Виды спорта, по которым проводятся соревнования.';
COMMENT ON COLUMN sport.sport_code IS 'Стабильный бизнес-код вида спорта.';

CREATE TABLE discipline (
    discipline_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sport_id            bigint       NOT NULL REFERENCES sport(sport_id),
    discipline_code     varchar(40)  NOT NULL,
    discipline_name     varchar(160) NOT NULL,
    competition_format  varchar(80),
    CONSTRAINT uq_discipline_per_sport UNIQUE (sport_id, discipline_code)
);

COMMENT ON TABLE discipline IS 'Спортивные дисциплины внутри вида спорта.';

CREATE TABLE organization (
    organization_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    organization_code   varchar(40)  NOT NULL UNIQUE,
    organization_name   varchar(200) NOT NULL,
    organization_type   varchar(30)  NOT NULL,
    phone               varchar(30),
    email               varchar(160),
    CONSTRAINT ck_organization_type CHECK (
        organization_type IN ('MUNICIPALITY','SPORT_CLUB','FEDERATION','SCHOOL',
                              'MEDICAL','SECURITY','SPONSOR','OTHER')
    )
);

COMMENT ON TABLE organization IS 'Организации, участвующие в подготовке и проведении соревнования.';

CREATE TABLE person (
    person_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_code     varchar(50)  NOT NULL UNIQUE,
    last_name       varchar(80)  NOT NULL,
    first_name      varchar(80)  NOT NULL,
    middle_name     varchar(80),
    birth_date      date,
    sex             char(1),
    phone           varchar(30),
    email           varchar(160),
    CONSTRAINT ck_person_sex CHECK (sex IS NULL OR sex IN ('M','F'))
);

COMMENT ON TABLE person IS 'Физические лица: спортсмены, тренеры, судьи и ответственные исполнители.';
COMMENT ON COLUMN person.person_code IS 'Внутренний неизменяемый код лица в информационной системе.';

CREATE TABLE venue (
    venue_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venue_code      varchar(40)  NOT NULL UNIQUE,
    venue_name      varchar(180) NOT NULL,
    address         varchar(300) NOT NULL,
    capacity        integer,
    is_indoor       boolean      NOT NULL DEFAULT false,
    CONSTRAINT ck_venue_capacity CHECK (capacity IS NULL OR capacity >= 0)
);

COMMENT ON TABLE venue IS 'Спортивные объекты и площадки проведения.';

-- ============================================================================
-- 2. Соревнование и его организационное окружение
-- ============================================================================

CREATE TABLE competition (
    competition_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    competition_code    varchar(40)  NOT NULL UNIQUE,
    competition_name    varchar(220) NOT NULL,
    sport_id            bigint       NOT NULL REFERENCES sport(sport_id),
    city                varchar(120) NOT NULL,
    start_date          date         NOT NULL,
    end_date            date         NOT NULL,
    registration_start  timestamptz,
    registration_end    timestamptz,
    status              varchar(20)  NOT NULL DEFAULT 'PLANNED',
    description         text,
    CONSTRAINT ck_competition_dates CHECK (end_date >= start_date),
    CONSTRAINT ck_registration_dates CHECK (
        registration_start IS NULL OR registration_end IS NULL OR
        registration_end >= registration_start
    ),
    CONSTRAINT ck_competition_status CHECK (
        status IN ('PLANNED','REGISTRATION','READY','RUNNING','FINISHED','CANCELLED')
    )
);

COMMENT ON TABLE competition IS 'Карточка городского спортивного соревнования.';

CREATE TABLE competition_organization (
    competition_id      bigint      NOT NULL REFERENCES competition(competition_id) ON DELETE CASCADE,
    organization_id     bigint      NOT NULL REFERENCES organization(organization_id),
    organization_role   varchar(30) NOT NULL,
    notes               text,
    PRIMARY KEY (competition_id, organization_id, organization_role),
    CONSTRAINT ck_comp_org_role CHECK (
        organization_role IN ('MAIN_ORGANIZER','CO_ORGANIZER','PARTNER','SPONSOR',
                              'MEDICAL_SUPPORT','SECURITY','VENUE_OPERATOR','OTHER')
    )
);

COMMENT ON TABLE competition_organization IS 'Роли организаций в подготовке конкретного соревнования.';

CREATE TABLE competition_venue (
    competition_id  bigint NOT NULL REFERENCES competition(competition_id) ON DELETE CASCADE,
    venue_id        bigint NOT NULL REFERENCES venue(venue_id),
    notes           text,
    PRIMARY KEY (competition_id, venue_id)
);

COMMENT ON TABLE competition_venue IS 'Площадки, утвержденные для конкретного соревнования.';

-- ============================================================================
-- 3. Спортсмены, команды и регистрация
-- ============================================================================

CREATE TABLE athlete (
    athlete_id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_id                   bigint      NOT NULL UNIQUE REFERENCES person(person_id),
    home_organization_id        bigint      REFERENCES organization(organization_id),
    sport_rank                  varchar(80),
    medical_clearance_until     date
);

COMMENT ON TABLE athlete IS 'Ролевая сущность спортсмена; персональные данные вынесены в person.';

CREATE TABLE team (
    team_id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    team_code           varchar(50)  NOT NULL UNIQUE,
    competition_id      bigint       NOT NULL REFERENCES competition(competition_id) ON DELETE CASCADE,
    organization_id     bigint       REFERENCES organization(organization_id),
    team_name           varchar(160) NOT NULL,
    coach_person_id     bigint       REFERENCES person(person_id),
    CONSTRAINT uq_team_name_competition UNIQUE (competition_id, team_name)
);

COMMENT ON TABLE team IS 'Команды, заявленные на конкретное соревнование.';

CREATE TABLE team_member (
    team_id         bigint      NOT NULL REFERENCES team(team_id) ON DELETE CASCADE,
    athlete_id      bigint      NOT NULL REFERENCES athlete(athlete_id),
    member_role     varchar(20) NOT NULL DEFAULT 'ATHLETE',
    PRIMARY KEY (team_id, athlete_id),
    CONSTRAINT ck_team_member_role CHECK (member_role IN ('ATHLETE','CAPTAIN','RESERVE'))
);

COMMENT ON TABLE team_member IS 'Состав команды на соревнование.';

CREATE TABLE registration (
    registration_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    registration_code  varchar(60)  NOT NULL UNIQUE,
    competition_id     bigint       NOT NULL REFERENCES competition(competition_id) ON DELETE CASCADE,
    athlete_id         bigint       REFERENCES athlete(athlete_id),
    team_id            bigint       REFERENCES team(team_id),
    registered_at      timestamptz  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status             varchar(20)  NOT NULL DEFAULT 'SUBMITTED',
    bib_number         varchar(20),
    CONSTRAINT ck_registration_target CHECK (
        (athlete_id IS NOT NULL AND team_id IS NULL) OR
        (athlete_id IS NULL AND team_id IS NOT NULL)
    ),
    CONSTRAINT ck_registration_status CHECK (
        status IN ('SUBMITTED','APPROVED','REJECTED','WITHDRAWN')
    )
);

COMMENT ON TABLE registration IS 'Регистрация индивидуального спортсмена ИЛИ команды на соревнование.';

-- Частичные уникальные индексы предотвращают повторную регистрацию одного и того же
-- спортсмена/команды на одно соревнование, сохраняя допустимость NULL во второй ветви.
CREATE UNIQUE INDEX uq_registration_athlete
    ON registration (competition_id, athlete_id)
    WHERE athlete_id IS NOT NULL;

CREATE UNIQUE INDEX uq_registration_team
    ON registration (competition_id, team_id)
    WHERE team_id IS NOT NULL;

-- ============================================================================
-- 4. Старты/события, заявки на старт и судейство
-- ============================================================================

CREATE TABLE competition_event (
    event_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_code      varchar(60)  NOT NULL UNIQUE,
    competition_id  bigint       NOT NULL REFERENCES competition(competition_id) ON DELETE CASCADE,
    discipline_id   bigint       NOT NULL REFERENCES discipline(discipline_id),
    venue_id        bigint       NOT NULL REFERENCES venue(venue_id),
    event_name      varchar(200) NOT NULL,
    start_ts        timestamptz  NOT NULL,
    end_ts          timestamptz,
    max_entries     integer,
    status          varchar(20)  NOT NULL DEFAULT 'PLANNED',
    CONSTRAINT ck_event_time CHECK (end_ts IS NULL OR end_ts >= start_ts),
    CONSTRAINT ck_event_max_entries CHECK (max_entries IS NULL OR max_entries > 0),
    CONSTRAINT ck_event_status CHECK (
        status IN ('PLANNED','READY','RUNNING','FINISHED','CANCELLED')
    )
);

COMMENT ON TABLE competition_event IS 'Конкретный старт/соревновательная единица в расписании.';

CREATE TABLE event_entry (
    entry_id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entry_code       varchar(70) NOT NULL UNIQUE,
    event_id         bigint      NOT NULL REFERENCES competition_event(event_id) ON DELETE CASCADE,
    registration_id  bigint      NOT NULL REFERENCES registration(registration_id) ON DELETE CASCADE,
    lane_or_order    varchar(30),
    seed_value       numeric(12,4),
    status           varchar(20) NOT NULL DEFAULT 'ENTERED',
    CONSTRAINT uq_event_registration UNIQUE (event_id, registration_id),
    CONSTRAINT ck_entry_status CHECK (
        status IN ('ENTERED','CONFIRMED','STARTED','FINISHED','DNS','DNF','DSQ','WITHDRAWN')
    )
);

COMMENT ON TABLE event_entry IS 'Допуск зарегистрированного участника/команды к конкретному старту.';

CREATE TABLE official_role (
    role_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_code    varchar(40)  NOT NULL UNIQUE,
    role_name    varchar(120) NOT NULL UNIQUE
);

COMMENT ON TABLE official_role IS 'Справочник судейских и технических ролей.';

CREATE TABLE official_assignment (
    assignment_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id       bigint  NOT NULL REFERENCES competition_event(event_id) ON DELETE CASCADE,
    person_id      bigint  NOT NULL REFERENCES person(person_id),
    role_id        bigint  NOT NULL REFERENCES official_role(role_id),
    is_chief       boolean NOT NULL DEFAULT false,
    notes          text,
    CONSTRAINT uq_official_assignment UNIQUE (event_id, person_id, role_id)
);

COMMENT ON TABLE official_assignment IS 'Назначение судей/официальных лиц на старты.';

-- ============================================================================
-- 5. Результаты и награждение
-- ============================================================================

CREATE TABLE result (
    result_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entry_id        bigint       NOT NULL UNIQUE REFERENCES event_entry(entry_id) ON DELETE CASCADE,
    place_no        integer,
    result_value    numeric(18,6),
    result_unit     varchar(20),
    result_text     varchar(120),
    points          numeric(12,3),
    is_disqualified boolean      NOT NULL DEFAULT false,
    notes           text,
    CONSTRAINT ck_result_place CHECK (place_no IS NULL OR place_no > 0)
);

COMMENT ON TABLE result IS 'Итог конкретного участника/команды в конкретном старте.';
COMMENT ON COLUMN result.result_text IS 'Текстовое представление результата (например, 00:10.42, 3:1, 6.25 м).';

CREATE TABLE award (
    award_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    result_id      bigint       NOT NULL REFERENCES result(result_id) ON DELETE CASCADE,
    award_type     varchar(20)  NOT NULL,
    award_title    varchar(160) NOT NULL,
    awarded_at     timestamptz,
    CONSTRAINT ck_award_type CHECK (
        award_type IN ('GOLD','SILVER','BRONZE','DIPLOMA','SPECIAL')
    ),
    CONSTRAINT uq_result_award UNIQUE (result_id, award_type, award_title)
);

COMMENT ON TABLE award IS 'Медали, дипломы и специальные награды, связанные с результатом.';

-- ============================================================================
-- 6. Организационный план: задачи и их порядок
-- ============================================================================

CREATE TABLE task_type (
    task_type_id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_type_code            varchar(40)  NOT NULL UNIQUE,
    task_type_name            varchar(160) NOT NULL UNIQUE,
    default_days_before_start integer,
    CONSTRAINT ck_task_days CHECK (default_days_before_start IS NULL OR default_days_before_start >= 0)
);

COMMENT ON TABLE task_type IS 'Типы организационных задач (разрешения, площадка, медицина, безопасность и т. п.).';

CREATE TABLE organization_task (
    task_id                      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_code                    varchar(60)  NOT NULL UNIQUE,
    competition_id               bigint       NOT NULL REFERENCES competition(competition_id) ON DELETE CASCADE,
    task_type_id                 bigint       NOT NULL REFERENCES task_type(task_type_id),
    responsible_organization_id  bigint       REFERENCES organization(organization_id),
    responsible_person_id        bigint       REFERENCES person(person_id),
    task_description             text         NOT NULL,
    planned_start                date,
    due_date                     date         NOT NULL,
    completed_at                 timestamptz,
    status                       varchar(20)  NOT NULL DEFAULT 'PLANNED',
    CONSTRAINT ck_task_status CHECK (
        status IN ('PLANNED','IN_PROGRESS','BLOCKED','DONE','CANCELLED')
    ),
    CONSTRAINT ck_task_dates CHECK (planned_start IS NULL OR due_date >= planned_start)
);

COMMENT ON TABLE organization_task IS 'Работы, которые необходимо выполнить для организации соревнования.';

CREATE TABLE task_dependency (
    task_id             bigint NOT NULL REFERENCES organization_task(task_id) ON DELETE CASCADE,
    predecessor_task_id bigint NOT NULL REFERENCES organization_task(task_id) ON DELETE CASCADE,
    PRIMARY KEY (task_id, predecessor_task_id),
    CONSTRAINT ck_task_not_self_dependency CHECK (task_id <> predecessor_task_id)
);

COMMENT ON TABLE task_dependency IS 'Предшествующие задачи; определяет порядок выполнения организационных работ.';

-- ============================================================================
-- 7. Индексы для внешних ключей и частых соединений
-- ============================================================================

CREATE INDEX ix_discipline_sport              ON discipline(sport_id);
CREATE INDEX ix_competition_sport             ON competition(sport_id);
CREATE INDEX ix_comp_org_organization         ON competition_organization(organization_id);
CREATE INDEX ix_comp_venue_venue              ON competition_venue(venue_id);
CREATE INDEX ix_athlete_home_org              ON athlete(home_organization_id);
CREATE INDEX ix_team_competition              ON team(competition_id);
CREATE INDEX ix_team_organization             ON team(organization_id);
CREATE INDEX ix_team_member_athlete           ON team_member(athlete_id);
CREATE INDEX ix_registration_competition      ON registration(competition_id);
CREATE INDEX ix_event_competition             ON competition_event(competition_id);
CREATE INDEX ix_event_discipline              ON competition_event(discipline_id);
CREATE INDEX ix_event_venue                   ON competition_event(venue_id);
CREATE INDEX ix_entry_registration            ON event_entry(registration_id);
CREATE INDEX ix_official_person               ON official_assignment(person_id);
CREATE INDEX ix_official_role                 ON official_assignment(role_id);
CREATE INDEX ix_award_result                  ON award(result_id);
CREATE INDEX ix_task_competition              ON organization_task(competition_id);
CREATE INDEX ix_task_type                     ON organization_task(task_type_id);
CREATE INDEX ix_task_resp_org                 ON organization_task(responsible_organization_id);
CREATE INDEX ix_task_resp_person              ON organization_task(responsible_person_id);
CREATE INDEX ix_task_dependency_predecessor   ON task_dependency(predecessor_task_id);

-- ============================================================================
-- 8. Дополнительные проверки предметной области через триггеры
-- ============================================================================

-- Проверяем, что дисциплина старта относится к тому же виду спорта, что и соревнование.
CREATE OR REPLACE FUNCTION fn_check_event_sport_consistency()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_competition_sport bigint;
    v_discipline_sport  bigint;
BEGIN
    SELECT sport_id INTO v_competition_sport
      FROM competition
     WHERE competition_id = NEW.competition_id;

    SELECT sport_id INTO v_discipline_sport
      FROM discipline
     WHERE discipline_id = NEW.discipline_id;

    IF v_competition_sport IS DISTINCT FROM v_discipline_sport THEN
        RAISE EXCEPTION 'Discipline % does not belong to competition sport', NEW.discipline_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_event_sport_consistency
BEFORE INSERT OR UPDATE OF competition_id, discipline_id
ON competition_event
FOR EACH ROW
EXECUTE FUNCTION fn_check_event_sport_consistency();

-- Проверяем, что площадка старта включена в перечень площадок соревнования.
CREATE OR REPLACE FUNCTION fn_check_event_venue_consistency()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM competition_venue cv
         WHERE cv.competition_id = NEW.competition_id
           AND cv.venue_id = NEW.venue_id
    ) THEN
        RAISE EXCEPTION 'Venue % is not approved for competition %', NEW.venue_id, NEW.competition_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_event_venue_consistency
BEFORE INSERT OR UPDATE OF competition_id, venue_id
ON competition_event
FOR EACH ROW
EXECUTE FUNCTION fn_check_event_venue_consistency();

-- Проверяем, что командная регистрация относится к соревнованию самой команды.
CREATE OR REPLACE FUNCTION fn_check_registration_team_consistency()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_team_competition bigint;
BEGIN
    IF NEW.team_id IS NOT NULL THEN
        SELECT competition_id INTO v_team_competition
          FROM team
         WHERE team_id = NEW.team_id;

        IF v_team_competition IS DISTINCT FROM NEW.competition_id THEN
            RAISE EXCEPTION 'Team % belongs to another competition', NEW.team_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_registration_team_consistency
BEFORE INSERT OR UPDATE OF competition_id, team_id
ON registration
FOR EACH ROW
EXECUTE FUNCTION fn_check_registration_team_consistency();

-- Проверяем, что регистрация и старт относятся к одному соревнованию.
CREATE OR REPLACE FUNCTION fn_check_entry_competition_consistency()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_event_competition bigint;
    v_reg_competition   bigint;
BEGIN
    SELECT competition_id INTO v_event_competition
      FROM competition_event
     WHERE event_id = NEW.event_id;

    SELECT competition_id INTO v_reg_competition
      FROM registration
     WHERE registration_id = NEW.registration_id;

    IF v_event_competition IS DISTINCT FROM v_reg_competition THEN
        RAISE EXCEPTION 'Registration % and event % belong to different competitions',
            NEW.registration_id, NEW.event_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_entry_competition_consistency
BEFORE INSERT OR UPDATE OF event_id, registration_id
ON event_entry
FOR EACH ROW
EXECUTE FUNCTION fn_check_entry_competition_consistency();

COMMIT;

-- Конец 3NF-скрипта.
