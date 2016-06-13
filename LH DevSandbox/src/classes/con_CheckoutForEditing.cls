public with sharing class con_CheckoutForEditing {

    // Invoked from custom Profile button called 'Edit Profile' (does not override Standard edit button but redirects to that page);
    // Parameters are ProfileID (id=) and checkin=0 if launching Edit operation or checkin=1 to check record back in.
    
    // In first iteration, try to check out record.
    // If already checked out, put up Error message with user's name who has record checked out.
    // Otherwise, redirect to standard Edit layout with return URL of the original VF page.
    // (We need to retain control because whatever happens (whether they hit save or cancel), the record needs to be unlocked!)
    
    // Retrieve Profile Id from URL and convert it to a Set of Ids to pass as parameter to RecordMaintenance methods.
    Id pId = ApexPages.currentPage().getParameters().get('Id');
    Set<Id> pIdSet = new Set<Id>{pId};
    // String retURL = ApexPages.currentPage().getParameters().get('retURL'); 

    // Retrieve checkin parameter from URL
    String checkinParm = ApexPages.currentPage().getParameters().get('checkin');
    Boolean checkIn = (checkinParm == '1') ? true : false;
    
    String userid = UserInfo.getUserId();
    
    public String checkedoutUser{get; set;}
    // public String message{get; set;}
    
    // Main method - determine what actions need to be performed.
    // DML operations (updating RecordCheckout: checking out/checking in) not allowed in constructor.
    public con_CheckoutForEditing(ApexPages.StandardController stdController) {

    }
    
    public PageReference redirectPage() {
    
        if (checkIn == true)
        {
            return checkinProfile();
        }
        else
        {
            return checkoutProfile();
        }
    }
        
    public PageReference checkinProfile() {
        // Check record back in and return to Profile record (browse mode).
        Map<Id, Record_Checkout__c> statMap = RecordMaintenance.CheckinRecords(pIdSet);
        return gotoBrowsePage();
    }
    
    
    public PageReference checkoutProfile() {
        // Attempt to check out record.
        Map<Id, Record_Checkout__c> statusMap = RecordMaintenance.CheckoutRecords(pIdSet);
        Record_Checkout__c rc = new Record_Checkout__c();
        rc = statusMap.get(pId);
        if (rc.User__c == userid)
        {
            // Record successfully checked out to user,
            // Redirect to edit page.
            return gotoEditPage();
        }
        else
        {
            // Put up error message
            this.checkedoutUser = rc.User_Name__c;
            return null;
        }
        
    }
    
    public PageReference gotoBrowsePage(){
        PageReference pr = new PageReference('/' + pId);
        pr.setRedirect(true);
        return pr;
    }
    
    public PageReference gotoEditPage(){
        String retPageName;
        String vfPageName = ApexPages.currentPage().getURL();
        if (vfPageName.contains('EditProfileWithRecordLocking')) 
        {
            retPageName = 'EditProfileWithRecordLocking';
        }
        else if(vfPageName.contains('EditParticipationWithRecordLocking'))
        {
            retPageName = 'EditParticipationWithRecordLocking';            
        }
        else
        {
            retPageName = 'EditAuthorizationWithRecordLocking';
        }

        PageReference p = new PageReference('/' + pId + '/e?retURL=/apex/'+retPageName+'?id='+pId+'%26checkin=1');
        // p.getParameters().put('id',pId);
        // p.getParameters().put('checkin', '1');
        p.setRedirect(true);
        return p;
    }   
    
}