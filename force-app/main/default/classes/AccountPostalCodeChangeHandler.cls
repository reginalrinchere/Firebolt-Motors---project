public class AccountPostalCodeChangeHandler {
    public static void handleChange(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        // Set collection to hold updated BillingPostalCodes
        Set<String> updatedZipCodes = new Set<String>();

        for (Account acc : newAccounts) {
            Account oldAcc = oldAccountsMap.get(acc.Id);

            // Check if BillingPostalCode has changed or is populated for the first time
            if ((oldAcc.BillingPostalCode == null && acc.BillingPostalCode != null) ||
                (oldAcc.BillingPostalCode != acc.BillingPostalCode && acc.BillingPostalCode != null)) {
                updatedZipCodes.add(acc.BillingPostalCode);
            }
        }

        // Exit early if no zip codes are updated
        if (updatedZipCodes.isEmpty()) {
            return;
        }

        // Query for Territory__c Owner and Zip_Code__c records related to updated zip codes
        List<Territory__c> territoryOwner = [
            SELECT Owner__c, Zip_Code__c
            FROM Territory__c
            WHERE Zip_Code__c IN :updatedZipCodes
        ];

        // Exit early if no matching Territory__c records are found
        if (territoryOwner.isEmpty()) {
            return;
        }

        // Map to associate zip codes with list of owner IDs
        Map<String, List<Id>> terrOwnerMap = new Map<String, List<Id>>();
        for (Territory__c terr : territoryOwner) {
            if (!terrOwnerMap.containsKey(terr.Zip_Code__c)) {
                terrOwnerMap.put(terr.Zip_Code__c, new List<Id>());
            }
            terrOwnerMap.get(terr.Zip_Code__c).add(terr.Owner__c);
        }

        // Lists to hold records to update and new Assignment_History__c records
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<Assignment_History__c> historyRecords = new List<Assignment_History__c>();

        for (Account acc : newAccounts) {
            Account oldAcc = oldAccountsMap.get(acc.Id);

            if ((oldAcc.BillingPostalCode == null && acc.BillingPostalCode != null) ||
                (oldAcc.BillingPostalCode != acc.BillingPostalCode && acc.BillingPostalCode != null)) {

                List<Id> owners = terrOwnerMap.get(acc.BillingPostalCode);
                if (owners != null && !owners.isEmpty()) {
                    // Randomly select one of the owners
                    Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), owners.size());
                    Id selectedOwner = owners[randomIndex];
                    acc.OwnerId = selectedOwner;

                    // Collect related Contacts for update
                    List<Contact> relatedContacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
                    for (Contact con : relatedContacts) {
                        con.OwnerId = selectedOwner;
                        contactsToUpdate.add(con);
                    }

                    // Collect related Opportunities for update
                    List<Opportunity> relatedOpps = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id];
                    for (Opportunity opp : relatedOpps) {
                        opp.OwnerId = selectedOwner;
                        opportunitiesToUpdate.add(opp);
                    }

                    // Create an Assignment_History__c record
                    Assignment_History__c history = new Assignment_History__c();
                    history.Account__c = acc.Id;
                    history.Previous_Owner__c = oldAcc.OwnerId;

                    // Find the previous and new territories
                    List<Territory__c> previousTerritories = [
                        SELECT Id FROM Territory__c WHERE Zip_Code__c = :oldAcc.BillingPostalCode
                    ];
                    List<Territory__c> newTerritories = [
                        SELECT Id FROM Territory__c WHERE Zip_Code__c = :acc.BillingPostalCode
                    ];

                    if (!previousTerritories.isEmpty()) {
                        history.Previous_Territory__c = previousTerritories[0].Id;
                    }
                    if (!newTerritories.isEmpty()) {
                        history.New_Territory__c = newTerritories[0].Id;
                    }

                    history.New_Owner__c = selectedOwner;
                    history.Changed_By__c = UserInfo.getUserId();
                    historyRecords.add(history);
                }
            }
        }

        // Update the records in bulk
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
        if (!historyRecords.isEmpty()) {
            insert historyRecords;
        }
    }
}