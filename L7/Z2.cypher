// Z2
CREATE (Dune:Movie {title:'Dune', released:2020, tagline:'Dune'})
CREATE (TheBatman:Movie {title:'The Batman', released:2022, tagline:'Welcome to the Real World'})
CREATE (Pattison:Person {name:'Robert Pattison', born:1985})
CREATE (XYZ:Person {name:'XYZ', born:1967})
SET Dune.stars = 8.4
SET Dune.boxOffice = 10000000
SET Dune.released = 2021
CREATE (Pattison)-[:ACTED_IN {roles:['Batman']}]->(TheBatman)
CREATE (XYZ)-[:ACTED_IN {roles:['xyz']}]->(TheBatman);
MATCH (p {name: 'XYZ'})-[r:ACTED_IN]->(TheBatman)
DELETE r
