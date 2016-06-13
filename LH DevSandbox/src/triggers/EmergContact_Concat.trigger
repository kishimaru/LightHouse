trigger EmergContact_Concat on EmergencyContact__c (after insert, after delete, after update) {

	Set<Id> profIds = new Set<Id>();

	for(EmergencyContact__c ec : trigger.isDelete ? trigger.Old : trigger.new) 
    {
        profIds.add(ec.Profile__c);
        System.debug('trigger profileID of EC record: '+ec.Profile__c);
	}
	
	ConcatEmergContact.UpdateProfileEC(profIds);
}