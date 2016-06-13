@isTest
public with sharing class EquipmentLoanGrantStatusTriggerTest {

// This tests a trigger on Equipment_Loan_Grant__c that runs on insert, update and delete: EquipmentLoanGrantStatusTrigger.
// Trigger calls EquipmentLoanGrantStatusUpdate class method that updates the status of related Equipment Inventory records.     
    
    static testmethod void EquipmentLoanGrantStatusUpdateTest ()
    {

        // Build test records
        // Check that Equipment Inventory records for each LoanGrant record has the right status.
        List<Equipment_Loan_Grant__c> neweqLoanGrantList = new List<Equipment_Loan_Grant__c>(InitTestRecords.InitTestEqLoanGrant(10));
        
        Set<Id> eqIds = new Set<Id>();
        for (Equipment_Loan_Grant__c eqLG : neweqLoanGrantList)
        {
            eqIds.add(eqLG.Equipment_Inventory__c);
        }
        
        Test.startTest();
        if (neweqLoanGrantList.size() > 0) insert neweqLoanGrantList;
        if (neweqLoanGrantList.size() > 0) update neweqLoanGrantList;
        Test.StopTest();
        ValidateEqStatus(eqIds);
        
    }
    
    static testmethod void UpdateEquipWithDeletesTest ()
    {
        // Build test records and then delete
        // Check that status of Equipment Inventory records for all of those deleted records is 'Available'.
        List<Equipment_Loan_Grant__c> neweqLoanGrantList = new List<Equipment_Loan_Grant__c>(InitTestRecords.InitTestEqLoanGrant(10));
        Set<Id> eqIds = new Set<Id>();
        for (Equipment_Loan_Grant__c eqLG : neweqLoanGrantList)
        {
            eqIds.add(eqLG.Equipment_Inventory__c);
        }
        
        Test.startTest();
        if (neweqLoanGrantList.size() > 0) insert neweqLoanGrantList;
        delete neweqLoanGrantList;
        Test.StopTest();
        ValidateDeletedEqLGs(eqIds);
        
    }
    
    static void ValidateEqStatus(Set<Id> updatedEqIds)
    {
        // Retrieve Equipment Inventory records (pulled from actual class)
        List<Equipment_Inventory__c> eqList = new List<Equipment_Inventory__c> (
            [SELECT Id, Grant_Loan_Status__c,
                (SELECT Id, Equipment_Inventory__c, Status__c FROM Equipment_Loan_Grant__r)
            FROM Equipment_Inventory__c WHERE Id IN : updatedEqIds]);
        
        String eqStatus;
    
        // For each Equipment in list, check status of child equiptmentLoanGrant records to update Equipment status.
        for (Equipment_Inventory__c thisEQ : eqList) {
            
            if (thisEQ.Equipment_Loan_Grant__r.size() > 0) {
            
                // Loop through each child Eq Loan Grant record to check statuses
                for (Equipment_Loan_Grant__c thisEQLoanGrant : thisEQ.Equipment_Loan_Grant__r) {
                    if (thisEQLoanGrant.Id != null) {
                        if ( thisEQLoanGrant.Status__c == 'Granted' ) {
                            eqStatus = 'Granted';
                        }
                        else if ( thisEQLoanGrant.Status__c == 'On loan' && eqStatus != 'Granted' ) {
                            eqStatus = 'On loan';
                        }
                    }
                }
            }
            
            if (eqStatus == null || eqStatus == '')
            {
                eqStatus = 'Available';
            }
            
            System.AssertEquals(eqStatus, thisEQ.Grant_Loan_Status__c);

            eqStatus = ''; // Reset eqStatus.
        }
   
    }
    
    static void ValidateDeletedEqLGs(Set<Id> updatedEqIds)
    {
        
        // Retrieve Equipment Inventory records
        List<Equipment_Inventory__c> eqList = new List<Equipment_Inventory__c> (
            [SELECT Id, Grant_Loan_Status__c
            FROM Equipment_Inventory__c WHERE Id IN : updatedEqIds]);
        
        for (Equipment_Inventory__c eq : eqList)
        {
            // System.debug('AL list validation deletes:' + pr.AllergyList__c);
            System.AssertEquals('Available', eq.Grant_Loan_Status__c );
        }
    }
    
    
    
}