//Z32
MATCH (d {name: "Cameron Crowe"})-[:DIRECTED]->(m:Movie)<-[:PRODUCED]-(p)
WHERE d=p 
RETURN DISTINCT m
