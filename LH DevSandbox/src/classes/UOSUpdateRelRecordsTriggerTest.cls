@isTest
public with sharing class UOSUpdateRelRecordsTriggerTest {

// This tests a trigger on Unit_of_Service__c that runs on insert, update and delete: UOSUpdateRelRecordsTrigger.
// Trigger calls UOSUpdateRecords class methods that update the Authorization (Units Provided) and Profile (first/last service dates).     
    
    static testmethod void UOSUpdateRelRecordsTest ()
    {

        // Build test records
        // Check that Auth and Profile records for each UOS record have the right number of Units Provided.
        List<Unit_of_Service__c> newUOSList = new List<Unit_of_Service__c>(InitTestRecords.InitTestUOSAuthsAndNoAuths(10,5));
        
        Set<Id> authIds = new Set<Id>();
        Set<Id> profIds = new Set<Id>();

        
        Test.startTest();
        if (newUOSList.size() > 0) insert newUOSList;
        
        for (Unit_of_Service__c uos : newUOSList)
        {
            authIds.add(uos.Authorization__c);
            System.debug('uos Participant Name: '+uos.Participant__r.Name);
            profIds.add(uos.Profile__c);
        }        
    
        ValidateTotalUnits(authIds, profIds);
        if (newUOSList.size() > 0) update newUOSList;
        ValidateTotalUnits(authIds, profIds);
        delete newUOSList;
        ValidateTotalUnits(authIds, profIds);
        Test.StopTest();
        
    }
   
    
    static void ValidateTotalUnits(Set<Id> updatedAuthIds, Set<Id> updatedProfIds)
    {
        // Retrieve UOS records for Authorization
        // Check that sum of all UOS Billable Units for a given Authorization equals that Authorization's Units of Service Provided field.
        
        List<Unit_of_Service__c> uosList = new List<Unit_of_Service__c> (
       	[SELECT Authorization__c, Authorization__r.Units_of_Service_Provided__c, Billable_Units__c FROM Unit_of_Service__c 
             WHERE Authorization__c IN : updatedAuthIds]);

        for (Unit_of_Service__c thisUOS : uosList) {
        
            System.debug('This UOS Authorization and provided: '+thisUOS.Authorization__c+'('+thisUOS.Authorization__r.Units_of_Service_Provided__c+')');
        }
        
        AggregateResult[] sumUnitsByAuth = 
            [SELECT Authorization__c, MAX(Authorization__r.Units_of_Service_Provided__c)uP, SUM(Billable_Units__c)sU FROM Unit_of_Service__c 
             WHERE Authorization__c != NULL AND Authorization__c IN : updatedAuthIds
             GROUP BY Authorization__c];  
        
        AggregateResult[] sumUnitsByProf = 
            [SELECT Profile__c, MAX(Profile__r.Date_of_First_Service__c)fP, MAX(Profile__r.Date_of_Last_Service__c)lP, MAX(Service_Date__c)lD, MIN(Service_Date__c)fD FROM Unit_of_Service__c 
             WHERE Canceled__c != True AND Profile__c IN : updatedProfIds
             GROUP BY Profile__c];
        
        
        for (AggregateResult ar : sumUnitsByAuth)  {
            // System.debug('Inside aggregate result');
            // System.debug('Calculated sum for this auth: '+ar.get('sU'));
            // System.debug('Authorization total provided field: '+ar.get('uP'));
			System.AssertEquals(ar.get('sU'), ar.get('uP'));
        }
        

        
        for (AggregateResult arP : sumUnitsByProf)  {
            System.debug('Profile date of first service: '+arP.get('fP'));
            System.debug('Profile date of last service: '+arP.get('lP'));
            System.debug('Min date aggtest: '+arP.get('fD'));
            System.debug('Max date aggtest: '+arP.get('lD'));
            
            System.AssertEquals(arP.get('fP'), arP.get('fD'));
            System.AssertEquals(arP.get('lP'), arP.get('lD'));


        }
        
        

        
    }
    
}