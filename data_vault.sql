

BEGIN;

DROP SCHEMA IF EXISTS dv CASCADE;
CREATE SCHEMA dv;
SET search_path = dv, public;

-- ============================================================================
-- 1. HUBS: устойчивые бизнес-ключи
-- ============================================================================

CREATE TABLE hub_sport (
    h_sport_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sport_code     varchar(30) NOT NULL UNIQUE,
    load_dts       timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source  varchar(100) NOT NULL
);
COMMENT ON TABLE hub_sport IS 'HUB вида спорта. Бизнес-ключ: sport_code.';

CREATE TABLE hub_discipline (
    h_discipline_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    discipline_code varchar(40) NOT NULL UNIQUE,
    load_dts         timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source    varchar(100) NOT NULL
);
COMMENT ON TABLE hub_discipline IS 'HUB спортивной дисциплины. Бизнес-ключ: discipline_code.';

CREATE TABLE hub_competition (
    h_competition_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    competition_code varchar(40) NOT NULL UNIQUE,
    load_dts          timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source     varchar(100) NOT NULL
);
COMMENT ON TABLE hub_competition IS 'HUB соревнования. Бизнес-ключ: competition_code.';

CREATE TABLE hub_venue (
    h_venue_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venue_code     varchar(40) NOT NULL UNIQUE,
    load_dts       timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source  varchar(100) NOT NULL
);
COMMENT ON TABLE hub_venue IS 'HUB площадки. Бизнес-ключ: venue_code.';

CREATE TABLE hub_organization (
    h_organization_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    organization_code varchar(40) NOT NULL UNIQUE,
    load_dts           timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source      varchar(100) NOT NULL
);
COMMENT ON TABLE hub_organization IS 'HUB организации. Бизнес-ключ: organization_code.';

CREATE TABLE hub_person (
    h_person_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_code    varchar(50) NOT NULL UNIQUE,
    load_dts       timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source  varchar(100) NOT NULL
);
COMMENT ON TABLE hub_person IS 'HUB физического лица. Бизнес-ключ: person_code.';

CREATE TABLE hub_team (
    h_team_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    team_code      varchar(50) NOT NULL UNIQUE,
    load_dts       timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source  varchar(100) NOT NULL
);
COMMENT ON TABLE hub_team IS 'HUB команды. Бизнес-ключ: team_code.';

CREATE TABLE hub_registration (
    h_registration_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    registration_code varchar(60) NOT NULL UNIQUE,
    load_dts           timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source      varchar(100) NOT NULL
);
COMMENT ON TABLE hub_registration IS 'HUB регистрации на соревнование. Бизнес-ключ: registration_code.';

CREATE TABLE hub_event (
    h_event_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_code     varchar(60) NOT NULL UNIQUE,
    load_dts       timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source  varchar(100) NOT NULL
);
COMMENT ON TABLE hub_event IS 'HUB старта/события. Бизнес-ключ: event_code.';

CREATE TABLE hub_task (
    h_task_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_code      varchar(60) NOT NULL UNIQUE,
    load_dts       timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source  varchar(100) NOT NULL
);
COMMENT ON TABLE hub_task IS 'HUB организационной задачи. Бизнес-ключ: task_code.';

CREATE TABLE hub_award (
    h_award_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    award_code     varchar(70) NOT NULL UNIQUE,
    load_dts       timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source  varchar(100) NOT NULL
);
COMMENT ON TABLE hub_award IS 'HUB награды. Бизнес-ключ: award_code.';

-- ============================================================================
-- 2. LINKS: отношения между бизнес-ключами
-- ============================================================================

CREATE TABLE lnk_discipline_sport (
    l_discipline_sport_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_discipline_id       bigint NOT NULL REFERENCES hub_discipline(h_discipline_id),
    h_sport_id            bigint NOT NULL REFERENCES hub_sport(h_sport_id),
    load_dts              timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source         varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_discipline_sport UNIQUE (h_discipline_id, h_sport_id)
);
COMMENT ON TABLE lnk_discipline_sport IS 'LINK: дисциплина принадлежит виду спорта.';

CREATE TABLE lnk_competition_sport (
    l_competition_sport_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_competition_id       bigint NOT NULL REFERENCES hub_competition(h_competition_id),
    h_sport_id             bigint NOT NULL REFERENCES hub_sport(h_sport_id),
    load_dts               timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source          varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_competition_sport UNIQUE (h_competition_id, h_sport_id)
);
COMMENT ON TABLE lnk_competition_sport IS 'LINK: соревнование проводится по виду спорта.';

CREATE TABLE lnk_competition_organization (
    l_competition_organization_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_competition_id              bigint NOT NULL REFERENCES hub_competition(h_competition_id),
    h_organization_id             bigint NOT NULL REFERENCES hub_organization(h_organization_id),
    load_dts                      timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source                 varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_comp_org UNIQUE (h_competition_id, h_organization_id)
);
COMMENT ON TABLE lnk_competition_organization IS 'LINK: организация участвует в подготовке соревнования.';

CREATE TABLE lnk_competition_venue (
    l_competition_venue_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_competition_id       bigint NOT NULL REFERENCES hub_competition(h_competition_id),
    h_venue_id             bigint NOT NULL REFERENCES hub_venue(h_venue_id),
    load_dts               timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source          varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_comp_venue UNIQUE (h_competition_id, h_venue_id)
);
COMMENT ON TABLE lnk_competition_venue IS 'LINK: площадка утверждена для соревнования.';

CREATE TABLE lnk_person_organization (
    l_person_organization_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_person_id              bigint NOT NULL REFERENCES hub_person(h_person_id),
    h_organization_id        bigint NOT NULL REFERENCES hub_organization(h_organization_id),
    load_dts                 timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source            varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_person_org UNIQUE (h_person_id, h_organization_id)
);
COMMENT ON TABLE lnk_person_organization IS 'LINK: членство/принадлежность лица организации.';

CREATE TABLE lnk_team_context (
    l_team_context_id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_team_id           bigint NOT NULL REFERENCES hub_team(h_team_id),
    h_competition_id    bigint NOT NULL REFERENCES hub_competition(h_competition_id),
    h_organization_id   bigint REFERENCES hub_organization(h_organization_id),
    load_dts            timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source       varchar(100) NOT NULL
);
COMMENT ON TABLE lnk_team_context IS 'LINK: команда относится к соревнованию и, при наличии, к организации.';
CREATE UNIQUE INDEX uq_lnk_team_context_with_org
    ON lnk_team_context(h_team_id, h_competition_id, h_organization_id)
    WHERE h_organization_id IS NOT NULL;
CREATE UNIQUE INDEX uq_lnk_team_context_without_org
    ON lnk_team_context(h_team_id, h_competition_id)
    WHERE h_organization_id IS NULL;

CREATE TABLE lnk_team_member (
    l_team_member_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_team_id        bigint NOT NULL REFERENCES hub_team(h_team_id),
    h_person_id      bigint NOT NULL REFERENCES hub_person(h_person_id),
    load_dts         timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source    varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_team_member UNIQUE (h_team_id, h_person_id)
);
COMMENT ON TABLE lnk_team_member IS 'LINK: лицо входит в состав команды.';

CREATE TABLE lnk_registration_person (
    l_registration_person_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_registration_id        bigint NOT NULL REFERENCES hub_registration(h_registration_id),
    h_competition_id         bigint NOT NULL REFERENCES hub_competition(h_competition_id),
    h_person_id              bigint NOT NULL REFERENCES hub_person(h_person_id),
    load_dts                 timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source            varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_reg_person UNIQUE (h_registration_id, h_competition_id, h_person_id)
);
COMMENT ON TABLE lnk_registration_person IS 'LINK: индивидуальная регистрация лица на соревнование.';

CREATE TABLE lnk_registration_team (
    l_registration_team_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_registration_id      bigint NOT NULL REFERENCES hub_registration(h_registration_id),
    h_competition_id       bigint NOT NULL REFERENCES hub_competition(h_competition_id),
    h_team_id              bigint NOT NULL REFERENCES hub_team(h_team_id),
    load_dts               timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source          varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_reg_team UNIQUE (h_registration_id, h_competition_id, h_team_id)
);
COMMENT ON TABLE lnk_registration_team IS 'LINK: командная регистрация на соревнование.';

CREATE TABLE lnk_event_context (
    l_event_context_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_event_id         bigint NOT NULL REFERENCES hub_event(h_event_id),
    h_competition_id   bigint NOT NULL REFERENCES hub_competition(h_competition_id),
    h_discipline_id    bigint NOT NULL REFERENCES hub_discipline(h_discipline_id),
    h_venue_id         bigint NOT NULL REFERENCES hub_venue(h_venue_id),
    load_dts           timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source      varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_event_context UNIQUE
        (h_event_id, h_competition_id, h_discipline_id, h_venue_id)
);
COMMENT ON TABLE lnk_event_context IS 'LINK: контекст старта — соревнование, дисциплина, площадка.';

CREATE TABLE lnk_event_registration (
    l_event_registration_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_event_id              bigint NOT NULL REFERENCES hub_event(h_event_id),
    h_registration_id       bigint NOT NULL REFERENCES hub_registration(h_registration_id),
    load_dts                timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source           varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_event_registration UNIQUE (h_event_id, h_registration_id)
);
COMMENT ON TABLE lnk_event_registration IS 'LINK: зарегистрированный участник/команда заявлен на конкретный старт.';

CREATE TABLE lnk_event_official (
    l_event_official_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_event_id          bigint NOT NULL REFERENCES hub_event(h_event_id),
    h_person_id         bigint NOT NULL REFERENCES hub_person(h_person_id),
    load_dts            timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source       varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_event_official UNIQUE (h_event_id, h_person_id)
);
COMMENT ON TABLE lnk_event_official IS 'LINK: официальное лицо назначено на старт.';

CREATE TABLE lnk_task_context (
    l_task_context_id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_task_id           bigint NOT NULL REFERENCES hub_task(h_task_id),
    h_competition_id    bigint NOT NULL REFERENCES hub_competition(h_competition_id),
    h_organization_id   bigint REFERENCES hub_organization(h_organization_id),
    load_dts            timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source       varchar(100) NOT NULL
);
COMMENT ON TABLE lnk_task_context IS 'LINK: задача относится к соревнованию и, при наличии, к ответственной организации.';
CREATE UNIQUE INDEX uq_lnk_task_context_with_org
    ON lnk_task_context(h_task_id, h_competition_id, h_organization_id)
    WHERE h_organization_id IS NOT NULL;
CREATE UNIQUE INDEX uq_lnk_task_context_without_org
    ON lnk_task_context(h_task_id, h_competition_id)
    WHERE h_organization_id IS NULL;

CREATE TABLE lnk_task_person (
    l_task_person_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_task_id        bigint NOT NULL REFERENCES hub_task(h_task_id),
    h_person_id      bigint NOT NULL REFERENCES hub_person(h_person_id),
    load_dts         timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source    varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_task_person UNIQUE (h_task_id, h_person_id)
);
COMMENT ON TABLE lnk_task_person IS 'LINK: ответственное лицо назначено на организационную задачу.';

CREATE TABLE lnk_task_dependency (
    l_task_dependency_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_task_id             bigint NOT NULL REFERENCES hub_task(h_task_id),
    h_predecessor_task_id bigint NOT NULL REFERENCES hub_task(h_task_id),
    load_dts              timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source         varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_task_dependency UNIQUE (h_task_id, h_predecessor_task_id),
    CONSTRAINT ck_dv_task_dependency_not_self CHECK (h_task_id <> h_predecessor_task_id)
);
COMMENT ON TABLE lnk_task_dependency IS 'LINK: зависимость между организационными задачами.';

CREATE TABLE lnk_entry_award (
    l_entry_award_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    h_event_id        bigint NOT NULL REFERENCES hub_event(h_event_id),
    h_registration_id bigint NOT NULL REFERENCES hub_registration(h_registration_id),
    h_award_id        bigint NOT NULL REFERENCES hub_award(h_award_id),
    load_dts          timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source     varchar(100) NOT NULL,
    CONSTRAINT uq_lnk_entry_award UNIQUE (h_event_id, h_registration_id, h_award_id)
);
COMMENT ON TABLE lnk_entry_award IS 'LINK: награда связана со стартом, регистрацией и бизнес-ключом награды.';

-- ============================================================================
-- 3. SATELLITES HUBS: описательный контекст и история
-- hashdiff хранит контрольную сумму описательных атрибутов, вычисляемую ETL.
-- ============================================================================

CREATE TABLE sat_sport_details (
    h_sport_id      bigint NOT NULL REFERENCES hub_sport(h_sport_id),
    load_dts        timestamptz NOT NULL,
    load_end_dts    timestamptz,
    hashdiff        char(32),
    sport_name      varchar(120) NOT NULL,
    record_source   varchar(100) NOT NULL,
    PRIMARY KEY (h_sport_id, load_dts),
    CONSTRAINT ck_sat_sport_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_sport_details IS 'SAT HUB sport: название вида спорта с историей.';

CREATE TABLE sat_discipline_details (
    h_discipline_id   bigint NOT NULL REFERENCES hub_discipline(h_discipline_id),
    load_dts          timestamptz NOT NULL,
    load_end_dts      timestamptz,
    hashdiff          char(32),
    discipline_name   varchar(160) NOT NULL,
    competition_format varchar(80),
    record_source     varchar(100) NOT NULL,
    PRIMARY KEY (h_discipline_id, load_dts),
    CONSTRAINT ck_sat_discipline_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_discipline_details IS 'SAT HUB discipline: описательные признаки дисциплины.';

CREATE TABLE sat_competition_details (
    h_competition_id   bigint NOT NULL REFERENCES hub_competition(h_competition_id),
    load_dts           timestamptz NOT NULL,
    load_end_dts       timestamptz,
    hashdiff           char(32),
    competition_name   varchar(220) NOT NULL,
    city               varchar(120) NOT NULL,
    start_date         date NOT NULL,
    end_date           date NOT NULL,
    registration_start timestamptz,
    registration_end   timestamptz,
    status             varchar(20) NOT NULL,
    description        text,
    record_source      varchar(100) NOT NULL,
    PRIMARY KEY (h_competition_id, load_dts),
    CONSTRAINT ck_sat_comp_dates CHECK (end_date >= start_date),
    CONSTRAINT ck_sat_comp_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_competition_details IS 'SAT HUB competition: изменяемый контекст соревнования.';

CREATE TABLE sat_venue_details (
    h_venue_id      bigint NOT NULL REFERENCES hub_venue(h_venue_id),
    load_dts        timestamptz NOT NULL,
    load_end_dts    timestamptz,
    hashdiff        char(32),
    venue_name      varchar(180) NOT NULL,
    address         varchar(300) NOT NULL,
    capacity        integer,
    is_indoor       boolean NOT NULL,
    record_source   varchar(100) NOT NULL,
    PRIMARY KEY (h_venue_id, load_dts),
    CONSTRAINT ck_sat_venue_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_venue_details IS 'SAT HUB venue: историзируемые характеристики площадки.';

CREATE TABLE sat_organization_details (
    h_organization_id bigint NOT NULL REFERENCES hub_organization(h_organization_id),
    load_dts           timestamptz NOT NULL,
    load_end_dts       timestamptz,
    hashdiff           char(32),
    organization_name  varchar(200) NOT NULL,
    organization_type  varchar(30) NOT NULL,
    phone              varchar(30),
    email              varchar(160),
    record_source      varchar(100) NOT NULL,
    PRIMARY KEY (h_organization_id, load_dts),
    CONSTRAINT ck_sat_org_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_organization_details IS 'SAT HUB organization: название, тип и контакты организации.';

CREATE TABLE sat_person_details (
    h_person_id     bigint NOT NULL REFERENCES hub_person(h_person_id),
    load_dts        timestamptz NOT NULL,
    load_end_dts    timestamptz,
    hashdiff        char(32),
    last_name       varchar(80) NOT NULL,
    first_name      varchar(80) NOT NULL,
    middle_name     varchar(80),
    birth_date      date,
    sex             char(1),
    phone           varchar(30),
    email           varchar(160),
    sport_rank      varchar(80),
    medical_clearance_until date,
    record_source   varchar(100) NOT NULL,
    PRIMARY KEY (h_person_id, load_dts),
    CONSTRAINT ck_sat_person_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_person_details IS 'SAT HUB person: персональный и спортивный контекст лица.';

CREATE TABLE sat_team_details (
    h_team_id      bigint NOT NULL REFERENCES hub_team(h_team_id),
    load_dts       timestamptz NOT NULL,
    load_end_dts   timestamptz,
    hashdiff       char(32),
    team_name      varchar(160) NOT NULL,
    record_source  varchar(100) NOT NULL,
    PRIMARY KEY (h_team_id, load_dts),
    CONSTRAINT ck_sat_team_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_team_details IS 'SAT HUB team: историзируемое название команды.';

CREATE TABLE sat_registration_details (
    h_registration_id bigint NOT NULL REFERENCES hub_registration(h_registration_id),
    load_dts           timestamptz NOT NULL,
    load_end_dts       timestamptz,
    hashdiff           char(32),
    registered_at      timestamptz NOT NULL,
    status             varchar(20) NOT NULL,
    bib_number         varchar(20),
    record_source      varchar(100) NOT NULL,
    PRIMARY KEY (h_registration_id, load_dts),
    CONSTRAINT ck_sat_registration_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_registration_details IS 'SAT HUB registration: статус регистрации и стартовый номер.';

CREATE TABLE sat_event_details (
    h_event_id      bigint NOT NULL REFERENCES hub_event(h_event_id),
    load_dts        timestamptz NOT NULL,
    load_end_dts    timestamptz,
    hashdiff        char(32),
    event_name      varchar(200) NOT NULL,
    start_ts        timestamptz NOT NULL,
    end_ts          timestamptz,
    max_entries     integer,
    status          varchar(20) NOT NULL,
    record_source   varchar(100) NOT NULL,
    PRIMARY KEY (h_event_id, load_dts),
    CONSTRAINT ck_sat_event_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_event_details IS 'SAT HUB event: название, расписание, лимит и статус старта.';

CREATE TABLE sat_task_details (
    h_task_id        bigint NOT NULL REFERENCES hub_task(h_task_id),
    load_dts         timestamptz NOT NULL,
    load_end_dts     timestamptz,
    hashdiff         char(32),
    task_type_code   varchar(40) NOT NULL,
    task_description text NOT NULL,
    planned_start    date,
    due_date         date NOT NULL,
    completed_at     timestamptz,
    status           varchar(20) NOT NULL,
    record_source    varchar(100) NOT NULL,
    PRIMARY KEY (h_task_id, load_dts),
    CONSTRAINT ck_sat_task_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_task_details IS 'SAT HUB task: содержание, сроки и статус организационной задачи.';

CREATE TABLE sat_award_details (
    h_award_id      bigint NOT NULL REFERENCES hub_award(h_award_id),
    load_dts        timestamptz NOT NULL,
    load_end_dts    timestamptz,
    hashdiff        char(32),
    award_type      varchar(20) NOT NULL,
    award_title     varchar(160) NOT NULL,
    awarded_at      timestamptz,
    record_source   varchar(100) NOT NULL,
    PRIMARY KEY (h_award_id, load_dts),
    CONSTRAINT ck_sat_award_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_award_details IS 'SAT HUB award: тип, название и дата вручения награды.';

-- ============================================================================
-- 4. SATELLITES LINKS: контекст отношений/транзакций
-- ============================================================================

CREATE TABLE sat_competition_organization_role (
    l_competition_organization_id bigint NOT NULL
        REFERENCES lnk_competition_organization(l_competition_organization_id),
    load_dts          timestamptz NOT NULL,
    load_end_dts      timestamptz,
    hashdiff          char(32),
    organization_role varchar(30) NOT NULL,
    notes              text,
    record_source      varchar(100) NOT NULL,
    PRIMARY KEY (l_competition_organization_id, load_dts),
    CONSTRAINT ck_sat_comp_org_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_competition_organization_role IS 'SAT LINK: роль организации в конкретном соревновании.';

CREATE TABLE sat_person_organization_context (
    l_person_organization_id bigint NOT NULL
        REFERENCES lnk_person_organization(l_person_organization_id),
    load_dts       timestamptz NOT NULL,
    load_end_dts   timestamptz,
    hashdiff       char(32),
    relation_type  varchar(30) NOT NULL,
    valid_from     date,
    valid_to       date,
    record_source  varchar(100) NOT NULL,
    PRIMARY KEY (l_person_organization_id, load_dts),
    CONSTRAINT ck_sat_person_org_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_person_organization_context IS 'SAT LINK: тип и период связи лица с организацией.';

CREATE TABLE sat_team_member_context (
    l_team_member_id bigint NOT NULL REFERENCES lnk_team_member(l_team_member_id),
    load_dts         timestamptz NOT NULL,
    load_end_dts     timestamptz,
    hashdiff         char(32),
    member_role      varchar(20) NOT NULL,
    record_source    varchar(100) NOT NULL,
    PRIMARY KEY (l_team_member_id, load_dts),
    CONSTRAINT ck_sat_team_member_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_team_member_context IS 'SAT LINK: роль лица в составе команды.';

CREATE TABLE sat_event_registration_entry (
    l_event_registration_id bigint NOT NULL
        REFERENCES lnk_event_registration(l_event_registration_id),
    load_dts        timestamptz NOT NULL,
    load_end_dts    timestamptz,
    hashdiff        char(32),
    entry_code      varchar(70) NOT NULL,
    lane_or_order   varchar(30),
    seed_value      numeric(12,4),
    status          varchar(20) NOT NULL,
    record_source   varchar(100) NOT NULL,
    PRIMARY KEY (l_event_registration_id, load_dts),
    CONSTRAINT ck_sat_entry_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_event_registration_entry IS 'SAT LINK: параметры допуска/заявки участника на старт.';

CREATE TABLE sat_event_registration_result (
    l_event_registration_id bigint NOT NULL
        REFERENCES lnk_event_registration(l_event_registration_id),
    load_dts        timestamptz NOT NULL,
    load_end_dts    timestamptz,
    hashdiff        char(32),
    place_no        integer,
    result_value    numeric(18,6),
    result_unit     varchar(20),
    result_text     varchar(120),
    points          numeric(12,3),
    is_disqualified boolean NOT NULL DEFAULT false,
    notes           text,
    record_source   varchar(100) NOT NULL,
    PRIMARY KEY (l_event_registration_id, load_dts),
    CONSTRAINT ck_sat_result_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_event_registration_result IS 'SAT LINK: историзируемый результат заявки на старт.';

CREATE TABLE sat_event_official_context (
    l_event_official_id bigint NOT NULL REFERENCES lnk_event_official(l_event_official_id),
    load_dts       timestamptz NOT NULL,
    load_end_dts   timestamptz,
    hashdiff       char(32),
    role_code      varchar(40) NOT NULL,
    is_chief       boolean NOT NULL DEFAULT false,
    notes          text,
    record_source  varchar(100) NOT NULL,
    PRIMARY KEY (l_event_official_id, load_dts),
    CONSTRAINT ck_sat_official_period CHECK (load_end_dts IS NULL OR load_end_dts > load_dts)
);
COMMENT ON TABLE sat_event_official_context IS 'SAT LINK: роль официального лица на старте.';

-- ============================================================================
-- 5. Индексы для ссылок
-- ============================================================================

CREATE INDEX ix_lnk_discipline_sport_sport ON lnk_discipline_sport(h_sport_id);
CREATE INDEX ix_lnk_comp_sport_sport ON lnk_competition_sport(h_sport_id);
CREATE INDEX ix_lnk_comp_org_org ON lnk_competition_organization(h_organization_id);
CREATE INDEX ix_lnk_comp_venue_venue ON lnk_competition_venue(h_venue_id);
CREATE INDEX ix_lnk_person_org_org ON lnk_person_organization(h_organization_id);
CREATE INDEX ix_lnk_team_context_comp ON lnk_team_context(h_competition_id);
CREATE INDEX ix_lnk_team_context_org ON lnk_team_context(h_organization_id);
CREATE INDEX ix_lnk_team_member_person ON lnk_team_member(h_person_id);
CREATE INDEX ix_lnk_reg_person_comp ON lnk_registration_person(h_competition_id);
CREATE INDEX ix_lnk_reg_person_person ON lnk_registration_person(h_person_id);
CREATE INDEX ix_lnk_reg_team_comp ON lnk_registration_team(h_competition_id);
CREATE INDEX ix_lnk_reg_team_team ON lnk_registration_team(h_team_id);
CREATE INDEX ix_lnk_event_context_comp ON lnk_event_context(h_competition_id);
CREATE INDEX ix_lnk_event_context_discipline ON lnk_event_context(h_discipline_id);
CREATE INDEX ix_lnk_event_context_venue ON lnk_event_context(h_venue_id);
CREATE INDEX ix_lnk_event_reg_registration ON lnk_event_registration(h_registration_id);
CREATE INDEX ix_lnk_event_official_person ON lnk_event_official(h_person_id);
CREATE INDEX ix_lnk_task_context_comp ON lnk_task_context(h_competition_id);
CREATE INDEX ix_lnk_task_context_org ON lnk_task_context(h_organization_id);
CREATE INDEX ix_lnk_task_person_person ON lnk_task_person(h_person_id);
CREATE INDEX ix_lnk_task_dependency_pred ON lnk_task_dependency(h_predecessor_task_id);
CREATE INDEX ix_lnk_entry_award_event ON lnk_entry_award(h_event_id);
CREATE INDEX ix_lnk_entry_award_registration ON lnk_entry_award(h_registration_id);
CREATE INDEX ix_lnk_entry_award_award ON lnk_entry_award(h_award_id);

-- Индексы для быстрого получения текущей (последней) версии спутника.
CREATE INDEX ix_sat_competition_latest ON sat_competition_details(h_competition_id, load_dts DESC);
CREATE INDEX ix_sat_person_latest ON sat_person_details(h_person_id, load_dts DESC);
CREATE INDEX ix_sat_event_latest ON sat_event_details(h_event_id, load_dts DESC);
CREATE INDEX ix_sat_task_latest ON sat_task_details(h_task_id, load_dts DESC);
CREATE INDEX ix_sat_result_latest ON sat_event_registration_result(l_event_registration_id, load_dts DESC);

COMMIT;

-- Конец Data Vault-скрипта.
