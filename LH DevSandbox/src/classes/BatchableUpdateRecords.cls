global class BatchableUpdateRecords implements Database.Batchable<sObject>{
    // Retrieves recordIds that need updating from RecordCheckout query and updates.
    
    global final String Query;
    
    // Query will be passed in as parameter and used by QueryLocator
    global BatchableUpdateRecords(String q)
    {
        query=q;
        System.debug('Inside BatchableUpdateRecords query ='+query);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> recIds = new Set<Id>();
        System.debug('Query: '+query);
        for(Sobject s : scope)
        {
            Record_Checkout__c rc = (Record_Checkout__c)s;
            recIds.add(rc.RecordID__c);
        }
        
        if (query.contains('Queue_for_Profile_update__c') && recIds.size() > 0)
        {
            // Clear out all records in Profile queue
            RecordMaintenance.ClearUpdateQueue('Profile');
                       
            // This sets things up for UpdateProfile method, which will add records to the queue that it can't update during its operation.
            // UpdateProfile will check out/in records for its updating.
            UOSUpdateRecords.UpdateProfile(recIds);
            
            // Also updates profile with list of allergies, medications and emergency contacts.
            // These will check out/in records for updating and queue those that are already locked for editing.
            ConcatAllergy.UpdateProfileAL(recIds);   
            ConcatEmergContact.UpdateProfileEC(recIds);
            ConcatMedTreatment.UpdateProfileMT(recIds);
            
        }
        else if (query.contains('Queue_for_Authorization_update__c') && recIds.size() > 0)
        {
            // Clear out records in Authorization queue
            RecordMaintenance.ClearUpdateQueue('Authorization');
            UOSUpdateRecords.UpdateAuth(recIds);
        }
        else if (query.contains('Queue_for_Participation_update__c') && recIds.size() > 0)
        {
            // Clear out records in Participation queue
            RecordMaintenance.ClearUpdateQueue('Participation');
            UOSUpdateRecords.UpdateParticipation(recIds);
        }

    }
    
    global void finish(Database.BatchableContext BC){
   
    }

}