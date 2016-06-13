trigger UOSUpdateRelRecordsTrigger on Unit_of_Service__c (after insert, after update, after delete) {

    Set<Id> authIds = new Set<Id>();
    Set<Id> profIds = new Set<Id>();
    
    For(Unit_of_Service__c uos : trigger.isDelete ? trigger.old : trigger.new)
    {
        If (trigger.isUpdate) {
            
            // If record updated, check to make sure we need to do any updates.

            Unit_of_Service__c uosbeforeUpdate = System.Trigger.oldMap.get(uos.Id);

            If ( uosbeforeUpdate.Authorization__c <> uos.Authorization__c ) 
            {
            	// Authorization has changed - update old and new
                if (uosbeforeUpdate.Authorization__c != null) authIds.add(uosbeforeUpdate.Authorization__c);
                if (uos.Authorization__c != null) authIds.add(uos.Authorization__c);
            }
            else if (uosbeforeUpdate.Billable_Units__c <> uos.Billable_Units__c)
            {
                // Auth hasn't changed but billable units has - update current Authorization
                if (uos.Authorization__c != null) authIds.add(uos.Authorization__c);
            }
            
            if (uosbeforeUpdate.Service_Date__c <> uos.Service_Date__c || 
                uosbeforeUpdate.Cancellation_Reason__c <> uos.Cancellation_Reason__c )
            {
                // The service date and/or cancellation (status) has changed - update Profile's dates of first/last service.
                // We are NOT accounting for situations where the Profile linked to the Unit of Service has changed!!
                // profIds.add(uos.Participant__r.Profile__c); this is null for some reason.
                profIds.add(uos.Profile__c);
            }
        }   
        
        else {
			
            // For newly created or deleted records, update both the Authorization (if there is one) and Profile.
            
        	if (uos.Authorization__c != null) authIds.add(uos.Authorization__c);
        	// profIds.add(uos.Participant__r.Profile__c); this is null for some reason.
            profIds.add(uos.Profile__c);
            System.debug('trigger uos ParticipationID: '+uos.Participant__c);
            System.debug('trigger uos Part ProfileID: '+uos.Participant__r.Profile__c);
            System.debug('trigger uos ProfileID: '+uos.Profile__c);
    	}
        
    }

    System.debug('Num of profiles: '+profIds.size());
    UOSUpdateRecords.UpdateProfile(profIds);
    UOSUpdateRecords.UpdateAuth(authIds);

}