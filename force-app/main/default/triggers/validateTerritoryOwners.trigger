trigger validateTerritoryOwners on Territory__c (before insert, before update) {
    // Step 1: Collect zip codes that are being inserted or updated
    Set<String> zipCodes = new Set<String>();
    for (Territory__c territory : Trigger.new) {
        zipCodes.add(territory.Zip_Code__c);
    }

    // Step 2: Query existing territories for the collected zip codes
    Map<String, Integer> zipCodeCounts = new Map<String, Integer>();
    for (AggregateResult result : [
        SELECT Zip_Code__c, COUNT(Id) cnt
        FROM Territory__c
        WHERE Zip_Code__c IN :zipCodes
        GROUP BY Zip_Code__c
    ]) {
        zipCodeCounts.put((String)result.get('Zip_Code__c'), (Integer)result.get('cnt'));
    }

    // Step 3: Check each record in the trigger to enforce the limit
    for (Territory__c territory : Trigger.new) {
        if (territory.Zip_Code__c != null) {
            Integer currentCount = zipCodeCounts.get(territory.Zip_Code__c);
            if (currentCount == null) {
                currentCount = 0;
            }

            // Increment the count if the record is new or if the zip code is being updated
            if (Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(territory.Id).Zip_Code__c != territory.Zip_Code__c)) {
                currentCount++;
            }

            // Validate the limit
            if (currentCount > 3) {
                territory.addError('You can not assign more than three Sales Representatives to a single zip code.');
            }
        }
    }
}