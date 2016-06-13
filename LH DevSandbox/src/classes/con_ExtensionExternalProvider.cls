public with sharing class con_ExtensionExternalProvider {

    private final Provider__c cntprovider;
    
    private ApexPages.StandardController stdController;  
    
    public con_ExtensionExternalProvider(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.cntprovider = (Provider__c)stdController.getRecord();

        Id recordId = stdController.getId();
        if(recordId == null) {
            cntprovider.Profile__c = ApexPages.currentPage().getParameters().get('masterid');
        }

        // When new contact and/or account created via buttons, record IDs passed via URL.
        if( ApexPages.currentPage().getParameters().get('cntid') != null )
        {
            String cntId = ApexPages.currentPage().getParameters().get('cntid');
            cntprovider.Contact__c = cntId;            
        }
        if( ApexPages.currentPage().getParameters().get('acctid') != null )
        {
            String acctId = ApexPages.currentPage().getParameters().get('acctid');
            cntprovider.Organization__c = acctId;
        }       
    
    }
  
    String mId = ApexPages.currentPage().getParameters().get('masterid');
    String recId = ApexPages.currentPage().getParameters().get('id');
    String aId = ApexPages.currentPage().getParameters().get('acctid');
    
    /* External Provider main page */
    
    public pageReference redirectProfile() {
        String retPageURL = '/' + cntprovider.Profile__c;
        PageReference retPage = new PageReference(retPageURL);
        retPage.setRedirect(true);
        return retPage;
    } 
    
    public pageReference saveandnewPage() {
        PageReference saveandnewPg = Page.NewOrEditExternalProvider;
        saveandnewPg.setRedirect(true);
        saveandnewPg.getParameters().put('masterid',cntprovider.Profile__c);
        return saveandnewPg;
    } 
    
    // Button: Save
    public PageReference save() {
        try {
            upsert cntprovider;
            return redirectProfile();
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
            upsert cntprovider;
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
        return redirectProfile();
    }
    
    // Button: New Organization and Contact
    public PageReference newOrgCnt() {
        PageReference newAcctCntPage = Page.ExtPNewAcctContact;
        newAcctCntPage.setRedirect(true);
        newAcctCntPage.getParameters().put('id',cntprovider.Id);
        newAcctCntPage.getParameters().put('masterid',cntprovider.Profile__c);
        return newAcctCntPage;
    }
    
    // Button: New Contact
    public PageReference newCnt() {
        if (cntprovider.Organization__c != null) {
            PageReference newCntPage = Page.ExtPNewContact;
            newCntPage.setRedirect(true);
            newCntPage.getParameters().put('id',cntprovider.Id);
            newCntPage.getParameters().put('masterid',cntprovider.Profile__c);
            newCntPage.getParameters().put('acctid',cntprovider.Organization__c);
            return newCntPage;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'Error: Select the organization with which your contact is affiliated or click New Organization & Contact if the organization is not yet in the system.'));
            return null;            
        }
    }
    
    /*

    Provider__c provider;
        
    public Provider__c getProvider() {
        if(provider == null)
            try {
                provider = [SELECT id, name, Organization__c, Contact__c, Profile__c, Referral_Source__c, Provider_Type__c, Notes__c FROM Provider__c
                        WHERE id =:ApexPages.currentPage().getParameters().get('id')];
            } catch (Exception e) {
                // Create a new ExternalProvider record and set profile from masterid in URL
                provider = new Provider__c();
                provider.Profile__c = ( ApexPages.currentPage().getParameters().get('masterid') != '' ) ? ApexPages.currentPage().getParameters().get('masterid') : '';
            }
        if( ApexPages.currentPage().getParameters().get('cntid') != null )
        {
            String cntId = ApexPages.currentPage().getParameters().get('cntid');
            provider.Contact__c = cntId;            
        }
        if( ApexPages.currentPage().getParameters().get('acctid') != null )
        {
            String acctId = ApexPages.currentPage().getParameters().get('acctid');
            provider.Organization__c = acctId;
        }
        return provider;
    }
    */

    // Declare a list of related Contacts to populate a pull-down for Contacts (rather than native lookup)
    public List<Contact> CntTemp = new List<Contact>();
      
    public List<SelectOption> RelContacts 
    {
        get
        {
            if(cntprovider.Organization__c != null) {
                CntTemp = [SELECT Id, Name FROM Contact WHERE AccountId =: cntprovider.Organization__c order by Name];
                Boolean isMemberFlag;
                RelContacts = new List<SelectOption>();
                RelContacts.add(new selectOption('', '--None--'));
                for (Contact temp : CntTemp)
                {
                    RelContacts.add(new SelectOption(temp.Id, temp.Name)); 
                    if ( cntprovider.Contact__c == temp.Id ) 
                    {
                        isMemberFlag = true;
                    }    
                }  
                if ( isMemberFlag != true ) 
                {
                    cntprovider.Contact__c = null;
                }        
                return RelContacts;
            } else {
                return null;
            }
        }
        set;
    }  


    /* EPNewAcctContact & EPNewContact Page */

    public PageReference retMainPage() {
        PageReference retMainPage = Page.NewOrEditExternalProvider;
        retMainPage.setRedirect(true);
        retMainPage.getParameters().put('id',recId);
        retMainPage.getParameters().put('masterid',mId);
        retMainPage.getParameters().put('acctid',aId); // This should only return the account ID that was passed originally via the URL -- not an ID of a newly created account.
        return retMainPage;
    }

    // EPNewAcctContact: Save New Account and New Contact
    public PageReference saveOrgCnt() {
        try {
            insert acct;
            ct.AccountId = acct.Id;
            ct.Phone = acct.Phone;
            ct.Fax = acct.Fax;
            ct.MailingCountryCode = acct.ShippingCountryCode;
            ct.MailingStreet = acct.ShippingStreet;
            ct.MailingCity = acct.ShippingCity;
            ct.MailingStateCode = acct.ShippingStateCode;
            ct.MailingPostalCode = acct.ShippingPostalCode;
            insert ct;
            PageReference pg = retMainPage();
            pg.getParameters().put('acctid',acct.Id);
            pg.getParameters().put('cntid',ct.Id);
            return pg;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return null;
        }   
    }
    
    public PageReference cancelOrgCnt() {
        return retMainPage();
    }
    
    // EPNewContact page: Save New Contact
    public PageReference saveCnt() {
        try 
        {    
            ct.AccountId = aId;
            insert ct;
            PageReference pg = retMainPage();
            pg.getParameters().put('acctid',aId);
            pg.getParameters().put('cntid',ct.Id);
            return pg;
        }
        catch(Exception exp)
        {
            ApexPages.addMessages(exp);
            return null;
        }
 
    }  
    
    public PageReference cancelCnt() {
        PageReference pg = retMainPage();
        pg.getParameters().put('acctid',aId);
        return pg;
    } 

    private String orgRecID () {
        try
        {
            RecordType recType;
            recType = [SELECT Id FROM RecordType where sobjecttype = 'Account' and name = 'Organization'];
            return recType.Id;
        }
        catch(Exception e)
        {
            return null;
        }
    }
    
    Account acct;   
    public Account getAcct() {
        acct = new Account();
        acct.RecordTypeId = orgRecID();        
        return acct;
    }
    
    Contact ct;  
    public Contact getCt() {
        ct = new Contact();        
        return ct;
    }
    
    
           
}