public with sharing class EquipmentLoanGrantStatusUpdate {

    public static void UpdateStatus (Set<Id> eqIds) 
    {
        // Retrieve Equipment Inventory records to update
        List<Equipment_Inventory__c> eqList = new List<Equipment_Inventory__c> (
        [SELECT Id, Grant_Loan_Status__c,
            (SELECT Id, Equipment_Inventory__c, Status__c FROM Equipment_Loan_Grant__r)
         FROM Equipment_Inventory__c WHERE Id IN : eqIds]); 
                
        List<Equipment_Inventory__c> eqToUpdate = new List<Equipment_Inventory__c>();
        
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
            
            thisEQ.Grant_Loan_Status__c = eqStatus;
            eqToUpdate.add(thisEQ);
            eqStatus = ''; // Reset eqStatus.
        }
    
        if (eqToUpdate.size() > 0) update eqToUpdate;     
        
    }
}