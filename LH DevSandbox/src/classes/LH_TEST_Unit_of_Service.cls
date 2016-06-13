@isTest(SeeAllData=true)
public class LH_TEST_Unit_of_Service {
	static testMethod void LH_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM Unit_of_Service__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Unit_of_Service__c()
            );
        }
    	Database.upsert(sourceList);
    }
}