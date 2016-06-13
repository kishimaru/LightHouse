trigger Medication_Concat on Medication_Treatment__c (after insert, after delete, after update) {

    Set<Id> profIds = new Set<Id>();

	for(Medication_Treatment__c mt : trigger.isDelete ? trigger.Old : trigger.new) 
    {
        profIds.add(mt.Profile__c);
        System.debug('trigger profileID of MT record: '+mt.Profile__c);
	}
    
    ConcatMedTreatment.UpdateProfileMT(profIds);
    
}