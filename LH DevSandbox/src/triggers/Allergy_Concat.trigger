trigger Allergy_Concat on Allergy__c (after insert, after delete, after update) {

    Set<Id> profIds = new Set<Id>();

	for(Allergy__c al : trigger.isDelete ? trigger.Old : trigger.new) 
    {
        profIds.add(al.Profile__c);
        System.debug('trigger profileID of AL record: '+al.Profile__c);
	}
    
    ConcatAllergy.UpdateProfileAL(profIds);
        
}