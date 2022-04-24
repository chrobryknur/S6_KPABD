// Z34
MATCH (p:Person)
WHERE SIZE((p)-[:ACTED_IN]-(:Movie)) > 3
RETURN p
