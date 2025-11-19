DROP TABLE IF EXISTS events;
CREATE TABLE events (
    event_time TIMESTAMP,
    event_type VARCHAR(50),
    product_id BIGINT,
    category_id BIGINT,
    category_code VARCHAR(100),
    brand VARCHAR(100),
    price FLOAT,
    user_id BIGINT,
    user_session VARCHAR(100)
);


SELECT *
FROM EVENTS
ORDER BY user_id
LIMIT 50000;