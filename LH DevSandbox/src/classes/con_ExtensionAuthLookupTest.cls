@isTest
public class con_ExtensionAuthLookupTest {
   
    public static testMethod void testMyController() {
        
        // Create test data
        Contact ct = new Contact(FirstName='MyFirst', LastName='MyLast');
        insert ct;
        
        Program__c pg = new Program__c(Name='MyPrg');
        insert pg;
        
        Location__c lc = new Location__c(Name='MyLoc');
        insert lc;
        
        date bdate = date.parse('7/9/1977');
        Profile__c pr = new Profile__c(Name='MyProfile', Contact__c=ct.Id, Birthdate__c=bdate);
        insert pr;
        
        Participation__c pt = new Participation__c(Name='MyPart', Program__c=pg.Id, Location__c=lc.Id, Profile__c=pr.Id);
        insert pt;
        
        date authdate = date.parse('12/27/2009');
        date startdate = date.parse('1/1/2010');
        date enddate = date.parse('1/31/2010');
        Authorization__c auth = new Authorization__c(Name='MyAuth', Authorization_Date__c  = authdate, Profile__c = pr.Id, Authorized_Units__c = 10.0, Participation__c = pt.Id, Authorization_Service_Start_Date__c = startdate, Authorization_Service_End_Date__c = enddate, Program__c = pg.Id);
		insert auth;
        
        date mydate = date.parse('1/30/2010');        
        Unit_of_Service__c uos = new Unit_of_Service__c(Participant__c=pt.Id, Service_Time__c=4, Service_Date__c=mydate, Authorization__c = auth.Id, Progress_Notes_Preview__c = '', Progress_Lesson_Notes__c = 'This is a test.' );
        insert uos;
        
        Test.startTest();
        
        // Create a new instance of controller extension con_ExtensionAuthLookup
        // This is another way to create instance of controller extension:
        // DemoControllerExtension testCtrl = new DemoControllerExtension(new ApexPages.StandardController(testAccount));
        ApexPages.StandardController conUOS = new ApexPages.StandardController(uos);
        con_ExtensionAuthLookup ext = new con_ExtensionAuthLookup(conUOS);
        
        // Establish starting page reference (participation detail record).
        String stPage = '/'+pt.Id;
        PageReference stpageRef = new PageReference(stPage);
        
        // First set test current page to VF page with no record id but master id (new record).
        String pageURLwithoutID = '/apex/uosNewOrEdit?masterid='+pt.Id+'&retURL=/'+pt.Id;
        PageReference pageRefNoID = new PageReference(pageURLwithoutID);
        Test.setCurrentPage(pageRefNoID);
        
        // Retrieve these get/set variables.
        List<SelectOption> aL = ext.AuthList;
        List<SelectOption> sL = ext.SvcList;
        List<SelectOption> eL = ext.eqList;
        List<SelectOption> pL = ext.PmtList;
        String aM = ext.authMessage;
        Decimal uL = ext.unitsLeftHidden;
           
        PageReference savePageWithoutId = ext.save(); // Catch exception.
        System.assertEquals(stpageRef.getUrl(),savePageWithoutId.getUrl());       
     
        // Test cancel and redirect back to starting page.
        PageReference cancelPage = ext.cancel();
        System.assertEquals(stpageRef.getUrl(),cancelPage.getUrl());
        
        // Set test current page to VF page with id.
        String pageURLwithID = '/apex/uosNewOrEdit?id='+uos.Id+'&retURL=/'+pt.Id;
        PageReference pageRef = new PageReference(pageURLwithID);
        System.Debug('Edit page ref: '+ pageRef);
        Test.setCurrentPage(pageRef);

		// Actually, this probably is not testing anything significant since those are values set.        
        system.assertEquals(4, uos.Service_Time__c);
        System.assertEquals(uos.Participant__c, pt.id); 
        
        // getUnitsRemaining function should look up UnitsRemaining field on Authorization linked to existing UOS record.
        Decimal uR = ext.getUnitsRemaining();        
        System.debug('uR = '+ uR);
        System.assertEquals(uR, 10);
        
        // This is the JS remoting function that should look up UnitsRemaining field on Authorization passed thru parameter.
        String aId=uos.Authorization__c;
       	String uLookup = con_ExtensionAuthLookup.getAuthString(aId);
        System.debug('concatenated text: '+uLookup);
       	String[] arrLookup = uLookup.split('[||]');
       	String uString = arrLookup[0];
        System.debug('string units left lookup: '+uString);
       	Decimal uRLookup = Decimal.valueof(uString);
        System.debug('decimal units left lookup: ' + uRLookup);
        System.assertEquals(uRLookup, 10.0);
         
        // Verify that save and new work.
        uos.Service_Time__c = 2;
        PageReference saveandnewPage = ext.saveandnew();  
        String afterSaveAndNewPage = ApexPages.currentPage().getURL();
        System.debug('After save page ref: '+saveandnewPage);
        System.debug('After save page: '+afterSaveAndNewPage);
        
        // Checks that values were saved.
        Unit_of_Service__c results = [Select Id, Service_Time__c From Unit_of_Service__c Where Id =: uos.Id];
        System.assertEquals(2, results.Service_Time__c);
        
        // Check that we are still on VF page
        System.assertEquals(pageRefNoID.getURL(),saveandnewPage.getURL());
        
        // Check save and copy.
        uos.Service_Time__c = 4;
        uos.Service_Date__c=mydate;
        PageReference saveandcopyPage = ext.saveandcopy();
        
        // Set test current page to VF page with clone set to true.
        String pageURLClone = '/apex/uosNewOrEdit?clone=1&id='+uos.Id+'&retURL=/'+pt.Id;
        PageReference pageRefClone = new PageReference(pageURLClone);
        Test.setCurrentPage(pageRefClone);
        
        PageReference savePage = ext.save(); 
        
        // Checks that values were saved in clone.
        Unit_of_Service__c resultsClone = [Select Id, Service_Time__c From Unit_of_Service__c Where Id =: uos.Id];
        System.assertEquals(4, resultsClone.Service_Time__c);
        
        // Checks that we landed on starting page.
        System.assertEquals(stpageRef.getUrl(),savePage.getUrl());
        
        // Reload VF page to test save
        // Test.setCurrentPage(pageRef);
        
       
        Test.stopTest();
    }
}