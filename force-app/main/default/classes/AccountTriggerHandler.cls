public with sharing class AccountTriggerHandler extends TriggerHandler {
    
    public void beforeInsertUpdate(List<Account> newAccounts, List<Account> oldAccounts, Map<Id, Account> newMapAccounts, Map<Id, Account> oldMapAccounts) {
        
        Account oldAccount = null;
    
        List<Account> updatedAccounts = new List<Account>();

        for(Account acc : newAccounts) {
            oldAccount = oldMapAccounts.get(acc.Id);

            if(oldAccount == null || acc.BillingPostalCode != oldAccount.BillingPostalCode) {
                updatedAccounts.add(acc);
            }
        }

        if(updatedAccounts.size() > 0) {
            AccountTriggerHelper.extractPostcodes(updatedAccounts);
        }
    }
}