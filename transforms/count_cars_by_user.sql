SELECT 
  users.id,
  users.full_name,
  COUNT(cars.id)
FROM 
  postgres_source_users AS users
LEFT JOIN 
  postgres_source_cars AS cars ON users.id = cars.user_id
GROUP BY 1, 2;
