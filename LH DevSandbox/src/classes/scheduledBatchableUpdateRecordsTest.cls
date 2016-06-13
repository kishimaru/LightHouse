@isTest
private class scheduledBatchableUpdateRecordsTest {

    // CRON expression: midnight on May 18.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 18 5 ? 2022';

    static testmethod void test() {
        
        String userid = UserInfo.getUserId();
        
        // Create test records
        List<Profile__c> pfs = new List<Profile__c>(InitTestRecords.InitTestProfiles(5));
        if (pfs.size() > 0) insert pfs;
        Set<Id> pfIds = (new Map<Id,Profile__c>(pfs)).keySet();
        
        List<Authorization__c> auths = new List<Authorization__c>(InitTestRecords.InitTestAuth(4));
        if (auths.size() > 0) insert auths;
        Set<Id> authIds = (new Map<Id,Authorization__c>(auths)).keySet();
        
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
        
        
        Test.startTest();

        // Schedule the test job
        String jobId = System.schedule('ScheduleBatchableClass',
                        CRON_EXP, 
                        new scheduledBatchableUpdateRecords());
         
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
            NextFireTime
            FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run
        System.assertEquals('2022-05-18 00:00:00', String.valueOf(ct.NextFireTime));
        
        Test.stopTest();
        
        // Not sure how to verify that it's run.  Batch test code successfully tests that batch works.

   }
}