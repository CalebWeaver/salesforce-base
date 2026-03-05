# Demo Data Seeding

Use anonymous Apex scripts to seed demo data. Don't build data factories — just create what you need.

## Seed Script

```apex
// scripts/seed-demo-data.apex
List<Account> accounts = new List<Account>{
    new Account(Name = 'Acme Corp', Industry = 'Technology'),
    new Account(Name = 'Global Industries', Industry = 'Manufacturing')
};
insert accounts;

List<Case> cases = new List<Case>{
    new Case(AccountId = accounts[0].Id, Subject = 'Routing Demo Case', Status = 'New', Priority = 'High'),
    new Case(AccountId = accounts[1].Id, Subject = 'Escalation Demo', Status = 'Open', Priority = 'Low')
};
insert cases;
```

## Running

```bash
sf apex run -f scripts/seed-demo-data.apex
```

## Tips

- Keep seed scripts in `scripts/` so they're easy to find and re-run
- Name them by what they set up: `seed-demo-data.apex`, `seed-routing-cases.apex`
- Hardcode field values — this isn't production code, readability matters more than flexibility
