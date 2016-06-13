trigger ContactRoleConcat on Contact_Role__c (after insert, after delete, after update) {

    Set<Id> ctIds = new Set<Id>();

	for(Contact_Role__c cr : trigger.isDelete ? trigger.Old : trigger.new) 
    {
        ctIds.add(cr.Contact__c);
        System.debug('trigger contactID of CR record: '+cr.Contact__c);
	}
    
    ConcatContactRoles.UpdateContact(ctIds);
        
}