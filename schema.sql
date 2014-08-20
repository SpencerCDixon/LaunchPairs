CREATE TABLE users(
  id serial PRIMARY KEY,
  uid varchar(255) NOT NULL,
  provider varchar(255) NOT NULL,
  username varchar(255) NOT NULL,
  name varchar(255) NOT NULL,
  email varchar(255) NOT NULL,
  avatar_url varchar(255) NOT NULL
);
