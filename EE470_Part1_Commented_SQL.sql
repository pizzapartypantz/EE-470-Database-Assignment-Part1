-- EE 470 - Database Assignment V2 - Part I
-- Student: Jason Hernandez-Downing
-- Purpose: Reproduce the Book/Price practice tables and five-node sensor database.


-- 1.1/1.2: Create and populate the example book table.
CREATE TABLE Book (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

INSERT INTO Book (id, name) VALUES
(1, 'MariaDB Book'),
(2, 'SQLDB Book'),
(3, 'MariaDB Book3'),
(4, 'MariaDB Book4'),
(5, 'MariaDB Book5');

-- The Price table uses Book.id as both its own primary key and a foreign key.
CREATE TABLE Price (
    id INT PRIMARY KEY,
    price DECIMAL(8,2) NOT NULL,
    FOREIGN KEY (id) REFERENCES Book(id)
) ENGINE=InnoDB;

INSERT INTO Price (id, price) VALUES
(1, 250.00),
(2, 252.00),
(3, 223.00),
(4, 194.00),
(5, 305.00);

-- Combine book names with their prices.
SELECT Book.name, Price.price
FROM Book INNER JOIN Price ON Book.id = Price.id
ORDER BY Book.id;

-- 1.3: Sensor registry: only listed node_name values are authorized.
CREATE TABLE sensor_register (
    node_name VARCHAR(10) PRIMARY KEY,
    manufacturer VARCHAR(10) NOT NULL,
    longitude DECIMAL(15,10) NOT NULL,
    latitude DECIMAL(15,10) NOT NULL
) ENGINE=InnoDB;

INSERT INTO sensor_register (node_name, manufacturer, longitude, latitude) VALUES
('node_1', 'Bosch', -122.4194000000, 37.7749000000),
('node_2', 'Sony', -121.8863000000, 37.3382000000),
('node_3', 'Siemens', -122.0322000000, 37.3230000000),
('node_4', 'Honeywell', -121.4944000000, 38.5816000000),
('node_5', 'Panasonic', -118.2437000000, 34.0522000000);

-- Composite primary key permits multiple readings per node but not at the same timestamp.
-- Foreign key blocks unknown nodes; CHECK constraints protect value ranges.
CREATE TABLE sensor_data (
    node_name VARCHAR(10) NOT NULL,
    time_received DATETIME NOT NULL,
    temperature DECIMAL(6,2) NOT NULL,
    humidity DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (node_name, time_received),
    FOREIGN KEY (node_name) REFERENCES sensor_register(node_name),
    CONSTRAINT chk_temperature CHECK (temperature BETWEEN -10 AND 100),
    CONSTRAINT chk_humidity CHECK (humidity BETWEEN 0 AND 100)
) ENGINE=InnoDB;

-- Simulated measurements begin at 11:00 AM on Oct. 1, 2022, every 30 minutes.
-- Each of the five registered nodes has four readings: 20 total.
INSERT INTO sensor_data (node_name, time_received, temperature, humidity) VALUES
('node_1','2022-10-01 11:00:00',22.50,55.00),
('node_1','2022-10-01 11:30:00',23.10,57.00),
('node_1','2022-10-01 12:00:00',24.00,56.00),
('node_1','2022-10-01 12:30:00',23.80,54.00),
('node_2','2022-10-01 11:00:00',25.20,60.00),
('node_2','2022-10-01 11:30:00',25.50,62.00),
('node_2','2022-10-01 12:00:00',26.10,61.00),
('node_2','2022-10-01 12:30:00',25.80,59.00),
('node_3','2022-10-01 11:00:00',20.10,48.00),
('node_3','2022-10-01 11:30:00',20.50,50.00),
('node_3','2022-10-01 12:00:00',21.00,49.00),
('node_3','2022-10-01 12:30:00',21.30,51.00),
('node_4','2022-10-01 11:00:00',28.00,45.00),
('node_4','2022-10-01 11:30:00',28.50,46.00),
('node_4','2022-10-01 12:00:00',29.10,44.00),
('node_4','2022-10-01 12:30:00',28.70,43.00),
('node_5','2022-10-01 11:00:00',19.50,70.00),
('node_5','2022-10-01 11:30:00',19.80,72.00),
('node_5','2022-10-01 12:00:00',20.20,71.00),
('node_5','2022-10-01 12:30:00',20.00,69.00);

-- A VIEW is a saved query, joining node information to its readings.
CREATE VIEW sensor_combined AS
SELECT d.node_name, r.manufacturer, r.longitude, r.latitude,
       d.time_received, d.temperature, d.humidity
FROM sensor_data AS d
INNER JOIN sensor_register AS r ON d.node_name = r.node_name;

-- Evidence queries: display both tables and the combined VIEW.
SELECT * FROM Book ORDER BY id;
SELECT * FROM Price ORDER BY id;
SELECT * FROM sensor_register ORDER BY node_name;
SELECT * FROM sensor_data ORDER BY node_name, time_received;
SELECT * FROM sensor_combined ORDER BY node_name, time_received;

-- Count all sensor records and verify the unregistered node has no readings.
SELECT COUNT(*) AS total_readings FROM sensor_data;
SELECT * FROM sensor_data WHERE node_name = 'node_99';

-- DEMONSTRATION ONLY: run the INSERT below SEPARATELY to show rejection.
-- It should produce error #1452 due to the sensor_data foreign key.
-- INSERT INTO sensor_data (node_name, time_received, temperature, humidity)
-- VALUES ('node_99','2022-10-01 13:00:00',25.00,60.00);

-- OPTIONAL CONSTRAINT TESTS: run each separately and expect rejection.
-- INSERT INTO sensor_data VALUES ('node_1','2022-10-01 13:00:00',101,50);
-- INSERT INTO sensor_data VALUES ('node_1','2022-10-01 13:00:00',20,101);
