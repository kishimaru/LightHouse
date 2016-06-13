trigger EquipmentLoanGrantStatusTrigger on Equipment_Loan_Grant__c (after insert, after delete, after update) {

    Set<Id> eqIds = new Set<Id>();
    
    For(Equipment_Loan_Grant__c eqLG : trigger.isDelete ? trigger.old : trigger.new)
    {
        If (trigger.isUpdate) {
            // If record updated, grab old equipment id as well if different from new equipment

            Equipment_Loan_Grant__c eqLGbeforeUpdate = System.Trigger.oldMap.get(eqLG.Id);

            If ( eqLGbeforeUpdate.Equipment_Inventory__c <> eqLG.Equipment_Inventory__c ) {
            
                eqIds.add(eqLGbeforeUpdate.Equipment_Inventory__c);
            }
        }   
        eqIds.add(eqLG.Equipment_Inventory__c);
    }
    
    EquipmentLoanGrantStatusUpdate.UpdateStatus(eqIds);

}