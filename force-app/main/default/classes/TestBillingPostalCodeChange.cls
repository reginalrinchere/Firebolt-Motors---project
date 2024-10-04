@isTest
public class TestBillingPostalCodeChange {

    @isTest
    static void testBillingPostalCodeUpdate() {
        // Step 1: Create test data

        // Create Territory records
        // Ensure the expected Owner__c is correctly assigned
        Territory__c terr1 = new Territory__c(Zip_Code__c='12345', Owner__c='005bm0000054vuTAAQ');
        Territory__c terr5 = new Territory__c(Zip_Code__c='12345', Owner__c='005bm000003W2PxAAK');
        Territory__c terr6 = new Territory__c(Zip_Code__c='12345', Owner__c='005bm000005aZqoAAE');
        Territory__c terr7 = new Territory__c(Zip_Code__c='12345', Owner__c='005bm000005aagPAAQ');
      
        
        Territory__c terr2 = new Territory__c(Zip_Code__c='67890', Owner__c='005bm000003W2PxAAK'); // Expected owner
        Territory__c terr3 = new Territory__c(Zip_Code__c='67890', Owner__c='005bm0000054vBJAAY');
        Territory__c terr4 = new Territory__c(Zip_Code__c='67890', Owner__c='005bm000005aZqoAAE');
        //Territory__c terr5 = new Territory__c(Zip_Code__c='67891', Owner__c='005bm000005aagPAAQ');
        insert new List<Territory__c>{ terr1, terr2, terr3, terr4, terr5, terr6, terr7};

        // Create an Account record with an initial postal code
        Account acc = new Account(Name='Test Account', BillingPostalCode='12345');
        insert acc;

        // Create related Contacts and Opportunities
        Contact con = new Contact(FirstName='John', LastName='Doe', AccountId=acc.Id);
        Opportunity opp = new Opportunity(Name='Test Opportunity', AccountId=acc.Id, StageName='Prospecting', CloseDate=Date.today());
        insert new List<SObject>{ con, opp };

        // Step 2: Update the Account to trigger the change
        // Update Account postal code to match a Territory record
        acc.BillingPostalCode = '67890';
        update acc;

        // Step 3: Verify results

        // Re-query the Account
        Account updatedAcc = [SELECT Id, OwnerId FROM Account WHERE Id = :acc.Id];
        // Check the correct Territory's Owner__c (Territory with postal code '67890')
        System.assertEquals(terr2.Owner__c, updatedAcc.OwnerId, 'Account owner should be updated based on new postal code.');

        // Verify Contacts
        Contact updatedCon = [SELECT Id, OwnerId FROM Contact WHERE Id = :con.Id];
        System.assertEquals(terr2.Owner__c, updatedCon.OwnerId, 'Contact owner should be updated based on new Account postal code.');

        // Verify Opportunities
        Opportunity updatedOpp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(terr2.Owner__c, updatedOpp.OwnerId, 'Opportunity owner should be updated based on new Account postal code.');

        // Clean up test data
        delete new List<SObject>{ con, opp, acc, terr1, terr2, terr3, terr4, terr5, terr6, terr7};
    }
}