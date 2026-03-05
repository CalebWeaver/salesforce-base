# Static Mock Data for POC

Drive the UI from static JSON when the demo is about the UI/UX, not the data flow. Switch to real Apex when the demo needs to show actual Salesforce data interaction.

## Import from Static Resource

```javascript
import MOCK_DATA from '@salesforce/resourceUrl/mockCaseData';
```

## Hardcode in Component

For true throwaway demos, skip the static resource and hardcode directly:

```javascript
const DEMO_CASES = [
    { Id: '001', Subject: 'Routing Issue', Status: 'Open', Priority: 'High' },
    { Id: '002', Subject: 'Escalation Request', Status: 'In Progress', Priority: 'Medium' }
];
```

## When to Use

- The demo is about the UI/UX, not the data flow
- You need to iterate on the frontend without waiting for Apex/data setup
- The demo audience won't be clicking through to record detail pages (fake IDs won't resolve)
