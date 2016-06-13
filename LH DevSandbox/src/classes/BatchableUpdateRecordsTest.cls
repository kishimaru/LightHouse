@isTest
private class BatchableUpdateRecordsTest {

    static testmethod void test() {
        // Create test records
        List<Profile__c> pfs = new List<Profile__c>(InitTestRecords.InitTestProfiles(5));
        if (pfs.size() > 0) insert pfs;
        Set<Id> pfIds = (new Map<Id,Profile__c>(pfs)).keySet();
        
        List<Authorization__c> auths = new List<Authorization__c>(InitTestRecords.InitTestAuth(4));
        if (auths.size() > 0) insert auths;
        Set<Id> authIds = (new Map<Id,Authorization__c>(auths)).keySet();
        
        List<Participation__c> parts = new List<Participation__c>(InitTestRecords.InitTestPart(5));
        if (parts.size() > 0) insert parts;
        Set<Id> ptIds = (new Map<Id,Participation__c>(parts)).keySet();
        
        
        List<Record_Checkout__c> rchList = new List<Record_Checkout__c>();
        for (Profile__c p : pfs)
        {
            rchList.add(new Record_Checkout__c (
                RecordID__c = p.Id, Queue_for_Profile_update__c = true));
        }
        if (rchList.size() > 0) insert rchList;
        
        List<Record_Checkout__c> rcAList = new List<Record_Checkout__c>();
        Integer firstAuth = 1;
        for (Authorization__c a : auths)
        {
            if (firstAuth == 1)
            {
                rcAList.add(new Record_Checkout__c (
                    RecordID__c = a.Id, Queue_for_Authorization_update__c = true));
            }
            firstAuth++;
        }
        if (rcAList.size() > 0) insert rcAList;
        
        List<Record_Checkout__c> rcPtList = new List<Record_Checkout__c>();
        for (Participation__c pt : parts)
        {
            rcPtList.add(new Record_Checkout__c (
                RecordID__c = pt.Id, Queue_for_Participation_update__c = true));
        }
        if (rcPtList.size() > 0) insert rcPtList;        
        
        
        String query = 'SELECT RecordID__c FROM Record_Checkout__c WHERE Queue_for_Profile_update__c = TRUE';
        String queryA = 'SELECT RecordID__c FROM Record_Checkout__c WHERE Queue_for_Authorization_update__c = TRUE';
        String queryPt = 'SELECT RecordID__c FROM Record_Checkout__c WHERE Queue_for_Participation_update__c = TRUE';
        
        Test.startTest();
        BatchableUpdateRecords bUpd = new BatchableUpdateRecords(query);
        Database.executeBatch(bUpd);
        
        BatchableUpdateRecords bUpdA = new BatchableUpdateRecords(queryA);
        Database.executeBatch(bUpdA);
        
        BatchableUpdateRecords bUpdPt = new BatchableUpdateRecords(queryPt);
        Database.executeBatch(bUpdPt);
        
        Test.stopTest();
        
        // Verify that there aren't any records in the queue anymore.
        List<Record_Checkout__c> pQueued = new List<Record_Checkout__c>([SELECT Id FROM Record_Checkout__c WHERE Queue_for_Profile_update__c = True]);
        System.assertEquals(0, pQueued.size());
    }
    
}