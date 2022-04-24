// Z31
MATCH (:Person {name: "Keanu Reeves"})-[:ACTED_IN]->(m:Movie)
RETURN m
