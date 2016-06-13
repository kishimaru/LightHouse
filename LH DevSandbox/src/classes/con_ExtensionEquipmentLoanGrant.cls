public class con_ExtensionEquipmentLoanGrant {

    // For custom VF page with button for adding new Equipment Inventory (coming from Participation!)
    // Master record is Participation.
    private final Equipment_Loan_Grant__c cnteqLoanGrant;
    
    private ApexPages.StandardController stdController;  
    
    public con_ExtensionEquipmentLoanGrant(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.cnteqLoanGrant = (Equipment_Loan_Grant__c)stdController.getRecord();

        Id recordId = stdController.getId();
        // If eqLoanGrant record not yet created, parent record IDs passed via URL.
        if(recordId == null && ApexPages.currentPage().getParameters().get('masterId') != '') {
            cnteqLoanGrant.Participation__c = ApexPages.currentPage().getParameters().get('masterid');
            
            // Prefilling Profile
            Participation__c part = [SELECT id, Name, Program__r.Id, Location__r.Id, Location_Picklist__c, Program__r.Name, Profile__r.Id, Profile__r.County__c, Profile__r.Birthdate__c from Participation__c where id = :ApexPages.currentPage().getParameters().get('masterId')];
            cnteqLoanGrant.Profile__c = part.Profile__r.Id;
         
        }
        
        // When new equipment created via buttons, record IDs passed via URL.
        if( ApexPages.currentPage().getParameters().get('equipid') != null )
        {
            String eId = ApexPages.currentPage().getParameters().get('equipid');
            cnteqLoanGrant.Equipment_Inventory__c = eId;            
        }
        
    }
  
    String mId = ApexPages.currentPage().getParameters().get('masterid');
    String recId = ApexPages.currentPage().getParameters().get('id');
    String eId = ApexPages.currentPage().getParameters().get('equipid');
    
    /* Equip Loan Grant main page */
    
    public pageReference redirectPart() {
        String retPageURL = '/' + cnteqLoanGrant.Participation__c;
        PageReference retPage = new PageReference(retPageURL);
        retPage.setRedirect(true);
        return retPage;
    } 
    
    public pageReference saveandnewPage() {
        PageReference saveandnewPg = Page.NewOrEditEquipmentLoanGrant;
        saveandnewPg.setRedirect(true);
        saveandnewPg.getParameters().put('masterid',cnteqLoanGrant.Participation__c);
        return saveandnewPg;
    } 
    
    // Button: Save
    public PageReference save() {
        try {
            upsert cnteqLoanGrant;
            return redirectPart();
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return null;
        }   
    }
    
    // Button: Save & New
    public PageReference saveandnew() {
        try {
            upsert cnteqLoanGrant;
            return saveandnewPage();
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return null;
        }   
    }    
    
    // Button: Cancel
    public PageReference cancel() {
        return redirectPart();
    }
    
    // Button: New Equipment
    public PageReference newEquip() {
        PageReference newEquipPage = Page.NewOrEditEquipmentLoanGrant_NewEquip;
        newEquipPage.setRedirect(true);
        newEquipPage.getParameters().put('id',cnteqLoanGrant.Id);
        newEquipPage.getParameters().put('masterid',cnteqLoanGrant.Participation__c);
        return newEquipPage;
    }
    

    /* NewOrEditEquipmentLoanGrant_NewEquip Page */

    public PageReference retMainPage() {
        PageReference retMainPage = Page.NewOrEditEquipmentLoanGrant;
        retMainPage.setRedirect(true);
        retMainPage.getParameters().put('id',recId);
        retMainPage.getParameters().put('masterid',mId);
        return retMainPage;
    }
    
    // Save New equipment
    public PageReference saveEquip() {
        try 
        {    
            insert equip;
            PageReference pg = retMainPage();
            pg.getParameters().put('equipid',equip.Id);
            return pg;
        }
        catch(Exception exp)
        {
            ApexPages.addMessages(exp);
            return null;
        }
    }  
    
    // Cancel equipment
    public PageReference cancelEquip() {
        PageReference pg = retMainPage();
        return pg;
    } 

    // Declare equipment inventory record
    Equipment_Inventory__c equip;
    public Equipment_Inventory__c getEquip() {
        equip = new Equipment_Inventory__c();
        return equip;
    }
    
    
           
}