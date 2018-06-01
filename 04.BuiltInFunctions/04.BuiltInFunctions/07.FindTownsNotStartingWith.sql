  SELECT T.TownID,
         T.Name
    FROM Towns AS t
   WHERE t.Name NOT LIKE '[RBD]%'
ORDER BY T.Name