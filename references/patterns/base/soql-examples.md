# SOQL Examples

## Optimized Query with Relationships

```apex
// ✅ Only needed fields, filtered, with relationship queries
List<Account> accounts = [
    SELECT Id, Name, (SELECT Id, FirstName FROM Contacts)
    FROM Account
    WHERE Id IN :accountIds
    WITH SECURITY_ENFORCED
];
```

## Key Rules

- Always use WHERE clauses and LIMIT when appropriate
- Use `WITH SECURITY_ENFORCED` to respect FLS
- Filter on indexed fields (standard, ExternalId, unique)
- Never put SOQL inside a loop
