// Z33
MATCH (p:Person)
WHERE NOT (p)-[:ACTED_IN]-(:Movie)
RETURN p
