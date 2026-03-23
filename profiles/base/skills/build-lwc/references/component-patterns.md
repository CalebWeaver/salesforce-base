# LWC Component Patterns

## Custom Labels

```javascript
import LABEL_SAVE from '@salesforce/label/c.Button_Save';
import LABEL_ERROR from '@salesforce/label/c.Error_GenericMessage';

export default class MyComponent extends LightningElement {
    label = {
        save: LABEL_SAVE,
        error: LABEL_ERROR
    };
}
```

```html
<template>
    <lightning-button label={label.save} onclick={handleSave}></lightning-button>
</template>
```

## Standard Components First

```html
<!-- Simple record view — no Apex needed -->
<lightning-record-view-form record-id={recordId} object-api-name="Account">
    <lightning-output-field field-name="Name"></lightning-output-field>
    <lightning-output-field field-name="Industry"></lightning-output-field>
</lightning-record-view-form>

<!-- Simple record edit — handles CRUD/FLS automatically -->
<lightning-record-edit-form record-id={recordId} object-api-name="Account"
    onsuccess={handleSuccess}>
    <lightning-input-field field-name="Name"></lightning-input-field>
    <lightning-input-field field-name="Industry"></lightning-input-field>
    <lightning-button type="submit" label="Save"></lightning-button>
</lightning-record-edit-form>
```

## Custom Event Communication

```javascript
// Child dispatches custom event
this.dispatchEvent(new CustomEvent('accountselected', {
    detail: { accountId: this.selectedId }
}));

// Parent listens
// <c-account-list onaccountselected={handleAccountSelected}></c-account-list>
handleAccountSelected(event) {
    this.selectedAccountId = event.detail.accountId;
}
```

## Meta XML Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/09/metadata">
    <apiVersion>59.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Account</object>
            </objects>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```
