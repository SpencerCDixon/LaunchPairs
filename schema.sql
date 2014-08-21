CREATE TABLE users(
  id serial PRIMARY KEY,
  uid varchar(255) NOT NULL,
  provider varchar(255) NOT NULL,
  username varchar(255) NOT NULL,
  name varchar(255) NOT NULL,
  email varchar(255) NOT NULL,
  avatar_url varchar(255) NOT NULL
);

CREATE TABLE profiles (
  id integer references users(id),
  blog varchar(255) ,
);

CREATE TABLE status (
  id integer references users(id),
  status varchar(255),
  created_at timestamp NOT NULL
);

CREATE TABLE pairs (

)


CREATE TABLE projects (
  id integer references users(id)

)


SELECT status FROM profiles;

# Adds data into status table
INSERT INTO status (id, status, created_at) VALUES (1,'doing something',now());


# Get the most recent status from someone?
SELECT DISTINCT ON users.id FROM users INNER JOIN status ON users.id=status.id ORDER BY users.id, status.date DESC LIMIT 1;

# Finds the most recent status available, not user dependent
select * from status order by created_at desc limit 1;

# Gets one based on ID
select * from status WHERE id = 2 order by created_at desc limit 1;
