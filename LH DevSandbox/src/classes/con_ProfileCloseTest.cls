@isTest
public class con_ProfileCloseTest {

        public static testMethod void testMyController() {
        
        // Create test data
        Contact ct = new Contact(FirstName='MyFirst', LastName='MyLast');
        insert ct;

        date bdate = date.parse('7/9/1977');
        Profile__c pr = new Profile__c(Name='MyProfile', Contact__c=ct.Id, Birthdate__c=bdate);
        insert pr;
        
        // Start test
        Test.startTest();
        ApexPages.StandardController conProf = new ApexPages.StandardController(pr);
        con_ProfileClose ext = new con_ProfileClose(conProf);

        // Set starting page
        String stPage = '/'+pr.Id;
        String pageURL = '/apex/ProfileClose?id='+pr.Id+'&retURL=/'+pr.Id;
        PageReference pageRef = new PageReference(pageURL);
        Test.setCurrentPage(pageRef);
    
        
        // First verify error message when Date Closed/Archived is empty.
        ext.Save_And_Archive();    
            
        List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
	    	if (msg.getDetail().contains('Please enter Date Closed/Archived')) b = true;
		}
		system.assert(b);
            
        // After save, check to see if new note was created and if Profile record has the right info in it.     
        Date d = Date.Today() ;
		pr.Date_Closed_Archived__c = d;
        // pr.Reason_for_Closure__c = 'Moved out of Service Area';
        pr.Closure_Details__c = 'Details on closing out';
        
        PageReference retPage = ext.Save_And_Archive();
        
        Profile__c upPr = [SELECT Date_Closed_Archived__c, Closure_Details__c FROM Profile__c WHERE Id =: pr.Id];
        Note nt = [SELECT Title, Body FROM Note WHERE ParentID =: pr.Id];
        
        System.assertEquals(upPr.Date_Closed_Archived__c, d); 
        System.assertEquals(nt.Body, upPr.Closure_Details__c);
        System.assertEquals(stPage.substring(0,15), retPage.getURL().substring(0,15));

		Test.stopTest();
        }
}