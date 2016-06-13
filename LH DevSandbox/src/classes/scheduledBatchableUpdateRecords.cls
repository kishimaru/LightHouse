global class scheduledBatchableUpdateRecords implements Schedulable {

    global void execute (SchedulableContext sc) {
        // Query profiles
        String q = 'SELECT RecordID__c FROM Record_Checkout__c WHERE Queue_for_Profile_update__c = TRUE';
        System.debug('scheduledBatchableUpdateRecords query: '+q);

        Id batchInstanceId = Database.executeBatch(new BatchableUpdateRecords(q)); 
        
        // Query participations
        String qP = 'SELECT RecordID__c FROM Record_Checkout__c WHERE Queue_for_Participation_update__c = TRUE';
        System.debug('scheduledBatchableUpdateRecords query: '+qP);

        Id batchInstanceIdP = Database.executeBatch(new BatchableUpdateRecords(qP)); 

        // Query authorizations
        String qA = 'SELECT RecordID__c FROM Record_Checkout__c WHERE Queue_for_Authorization_update__c = TRUE';
        System.debug('scheduledBatchableUpdateRecords query: '+qA);

        Id batchInstanceIdA = Database.executeBatch(new BatchableUpdateRecords(qA)); 
    }
    
}