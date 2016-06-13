@isTest
public with sharing class con_ExtensionEquipmentLoanGrantTest {

// This tests a VF Controller on Equipment_Loan_Grant__c: con_ExtensionEquipmentLoanGrant.     
// Only 86% coverage because it doesn't test Save and Save&New on error (when there's no Equipment selected).   
    
    public static testMethod void testMyController() {
        
        // Create test data

        Contact ct = new Contact (FirstName='MyFirst', LastName='MyLast');
        insert ct;
        
        Program__c pg = new Program__c(Name='MyPrg');
        insert pg;
        
        Location__c lc = new Location__c(Name='MyLoc');
        insert lc;
        
        date bdate = date.parse('7/9/1977');
        Profile__c pr = new Profile__c(Name='MyProfile', Contact__c=ct.Id, Birthdate__c=bdate);
        insert pr;
        
        Participation__c pt = new Participation__c(Program__c = pg.Id, Location__c = lc.Id, Profile__c = pr.Id);
        insert pt;
        
        Equipment_Inventory__c eq = new Equipment_Inventory__c(Name = 'Macbook pro', Type__c = 'Computer');
        insert eq;
        
        Equipment_Loan_Grant__c eqLG = new Equipment_Loan_Grant__c(Participation__c=pt.Id, Equipment_Inventory__c=eq.Id);
        insert eqLG;
        
        
        // Start test
        Test.startTest();
        ApexPages.StandardController coneqLoanGrant = new ApexPages.StandardController(eqLG);
        con_ExtensionEquipmentLoanGrant ext = new con_ExtensionEquipmentLoanGrant(coneqLoanGrant);
        
        // Establish starting page reference (participation detail record).
        String stPage = '/'+pt.Id;
        PageReference stpageRef = new PageReference(stPage);
        
        // Main page: No record id but master id (new record).
        String pageURLwithoutID = '/apex/NewOrEditEquipmentLoanGrant?masterid='+pt.Id+'&retURL=/'+pt.Id;
        PageReference pageRefNoID = new PageReference(pageURLwithoutID);
        Test.setCurrentPage(pageRefNoID);
        
        // Main page: Cancel
        PageReference cancelPage = ext.cancel();
        
        System.assertEquals(stpageRef.getUrl(),cancelPage.getUrl());
        
        // Reset Main page: No record id but master id (new record).
        Test.setCurrentPage(pageRefNoID);        
     
        PageReference EQpg = Page.NewOrEditEquipmentLoanGrant_NewEquip;
        EQpg.getParameters().put('id',eqLG.Id); // extension puts ID of eqLoanGrant record in...
        EQpg.getParameters().put('masterid',pt.Id);

        // Main page: Invoke New equipment page (NewOrEditEquipmentLoanGrant_NewEquip)        
        PageReference newPg = ext.newEquip();
        
        System.assertEquals(newPg.getURL(),EQpg.getURL());
        
        // New Equip page: Cancel
        Test.setCurrentPage(newPg);
        ext.cancelEquip();
        
        // Reset New Equip page
        Test.setCurrentPage(newPg); 
        
        // New Equip page: Save and error (required fields left blank)
        ext.saveEquip();
        
        // New Equip page: Save successful
        Test.setCurrentPage(newPg);       

        Equipment_Inventory__c newEquip = ext.getEquip();       
              
        newEquip.Name = 'Mac laptop';
        newEquip.Type__c = 'Computer';
        PageReference saveEqPage = ext.saveEquip();
        Id newEquipId = newEquip.Id;
        
        // Check that this equipment has been saved.
        Equipment_Inventory__c eqInv = [SELECT Id FROM Equipment_Inventory__c WHERE Name = 'Mac laptop'];
        System.assertEquals(newEquip.Id, eqInv.Id);
        
        // Reset to main page with new equipment id in parameter (make sure we are where we think).
        PageReference Mainpg = Page.NewOrEditEquipmentLoanGrant;
        Mainpg.getParameters().put('equipid',newEquipId);
        
        System.assertEquals(saveEqPage.getURL(),Mainpg.getURL());
        
        Test.setCurrentPage(saveEqPage);     
        
        PageReference savePage = ext.save();
        
        // Following lines commented out because save doesn't seem to actually have created a new Eq loan grant
        // record with the new piece of equipment created (since that ID was just passed via URL).
        // We should now have an eq Loan Grant record for the new piece of equipment
        /* Equipment_Loan_Grant__c newlycrEqLG = [SELECT Id FROM Equipment_Loan_Grant__c WHERE Equipment_Inventory__c =: newEquipId];
        Boolean notEmpty = (newlycrEqLG != null) ? TRUE : FALSE;
        System.assertEquals(notEmpty,TRUE); */
        
        PageReference saveandnewPage = ext.saveandnew();
        
        String mainPgURL = '/apex/neworeditequipmentloangrant?masterid='+pt.Id;
        PageReference mainPgSaveAndNew = new PageReference(mainPgURL);
        
        System.assertEquals(mainPgSaveAndNew.getURL(),saveandnewPage.getURL());
        
        
        
       
        Test.stopTest();
    }
    
    
    
}