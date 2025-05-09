-- HA 1
-- Author: Elena Ibraeva
-- Topics: CREATE TABLE, FOREIGN KEYS, INSERT, CASCADE

-- Users
CREATE TABLE app_user (
  user_id SERIAL PRIMARY KEY,
  user_name VARCHAR(80) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trips
CREATE TABLE trip (
  trip_id SERIAL PRIMARY KEY,
  trip_name VARCHAR(500) NOT NULL,
  start_date DATE NULL,
  user_id INT NOT NULL
);

-- Cities
CREATE TABLE city (
  city_id INT NOT NULL,
  city_name VARCHAR(50) NOT NULL,
  country_name VARCHAR(50) NOT NULL,
  is_capital BOOLEAN NOT NULL
);

-- Trip Cities (destinations)
CREATE TABLE trip_cities (
  trip_id INT NOT NULL,
  ord_number INT NOT NULL,
  city_id INT NOT NULL,
  stay_duration INT NULL,
  CONSTRAINT fk_trip FOREIGN KEY (trip_id) REFERENCES trip(trip_id) ON DELETE CASCADE,
  CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id) ON DELETE CASCADE
);

-- Insert sample cities
INSERT INTO city (city_id, city_name, country_name, is_capital)
VALUES
  (1,'Moscow', 'Russia', TRUE),
  (2,'Berlin', 'Germany', TRUE),
  (3,'Perm', 'Russia', FALSE),
  (4,'Madrid', 'Spain', TRUE),
  (5,'Amsterdam', 'Netherlands', TRUE);

-- Insert trips
INSERT INTO trip (trip_name, start_date, user_id) VALUES
  ('trip_1', '2025-02-07', 567),
  ('trip_2', '2025-02-01', 568);

-- Link cities to trips
INSERT INTO trip_cities (trip_id, ord_number, city_id, stay_duration)
VALUES
  (1, 123, 1, 50),
  (2, 456, 2, 60);
