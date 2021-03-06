-- # Adds data into status table
-- INSERT INTO status (user_id, status, created_at) VALUES (2,'doing something',now());
--
-- # Get the most recent status from someone?
-- SELECT DISTINCT ON users.id FROM users INNER JOIN status ON users.id=status.id ORDER BY users.id, status.date DESC LIMIT 1;
--
-- # Finds the most recent status available based on ID
-- select * from status WHERE id = 2 order by created_at desc limit 1;


-- ##### NEW DATABASE DESIGN PREPARATION #########
CREATE TABLE users(
  id serial PRIMARY KEY,
  uid varchar(255) NOT NULL,
  provider varchar(255) NOT NULL,
  username varchar(255) NOT NULL,
  name varchar(255) NOT NULL,
  email varchar(255) NOT NULL,
  avatar_url varchar(255) NOT NULL,
  blog_url varchar(255)
);

CREATE TABLE status (
  id serial PRIMARY KEY,
  user_id integer REFERENCES users(id),
  status varchar(255),
  created_at timestamp NOT NULL
);

CREATE TABLE pairings (
  id serial PRIMARY KEY,
  user_id integer REFERENCES users(id),
  pair_id integer REFERENCES users(id)
);

CREATE TABLE projects (
  id serial PRIMARY KEY,
  user_id integer REFERENCES users(id),
  project varchar(255),
  created_at timestamp NOT NULL
);

CREATE TABLE personal_info (
  id serial PRIMARY KEY,
  user_id integer REFERENCES users(id),
  breakable_toy text,
  phone_number varchar(30),
  blog_url varchar(255),
  twitter varchar(80),
  linkedin varchar(100),
  created_at timestamp NOT NULL
);
