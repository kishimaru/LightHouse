global with sharing class con_ExtensionAuthLookup {

    private final Unit_of_Service__c unitOfService;

    // The extension constructor initializes the private member
    // variable unitOfService by using the getRecord method from the standard
    // controller.
    
    private ApexPages.StandardController stdController; 
    // Declaring stdController so that standard controller save and cancel can be invoked in other methods below. 
    
    public String mID = ApexPages.currentPage().getParameters().get('masterId');
    public String recID = ApexPages.currentPage().getParameters().get('Id');
    public String retURL = ApexPages.currentPage().getParameters().get('retURL');    
    // Declaring strings to help build URL used in Save and New below.
    
    public con_ExtensionAuthLookup(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.unitOfService = (Unit_of_Service__c)stdController.getRecord();

        // When creating brand new record, default program and participation based on parent and Service Provider to currently logged in user. (masterid set in URL)
        Id recordId = stdController.getId();
        if(recordId == null && ApexPages.currentPage().getParameters().get('masterId') != '')
        {
            unitOfService.Service_Provider__c = UserInfo.getUserId(); 
            Participation__c part = [SELECT id, Name, Program__r.Id, Location__r.Id, Location_Picklist__c, Program__r.Name, Profile__r.Id, Profile__r.County__c, Profile__r.Birthdate__c from Participation__c where id = :ApexPages.currentPage().getParameters().get('masterId')];
            // Included County and Birthdate in lookup so at some point these can be made visible (read-only) in this layout.  Punting for now.
            unitOfService.Participant__c = part.id;
            unitOfService.Program__c = part.Program__r.Id;
            unitOfService.Profile__c = part.Profile__r.Id;
            unitOfService.Location_Picklist__c = part.Location_Picklist__c;
            // unitOfService.Location__c = part.Location__r.Id; Field not needed anymore.
            // Bailed on removing link from participant field. Cannot figure out how to retrieve name and set unitOfService.Participant__r.Name.
            // unitOfService.Delivery_of_Services__c = "Individual"; Bailed on setting default value to Individual. Requires looking up picklist values with schema from metadata api and displaying list:
            // https://developer.salesforce.com/blogs/developer-relations/2008/12/using-the-metadata-api-to-retrieve-picklist-values.html
        } 
    }
    
    // Declare a list of Authorizations to populate a pull-down (rather than native lookup)
    public List<Authorization__c> AuthTemp = new List<Authorization__c>();
    
    public List<SelectOption> AuthList
        {
            get
            {
                AuthTemp = [SELECT id, Name From Authorization__c WHERE Participation__c =: unitOfService.Participant__c ORDER BY Authorization_Date__c DESC NULLS LAST];
                AuthList = new List<SelectOption>();
                AuthList.add(new selectOption('', '--None--'));
                for(Authorization__c temp : AuthTemp)
                {
                    AuthList.add(new SelectOption(temp.Id, temp.Name));
                }
                return AuthList;
            }
            set;
        }
    
    // Declare a list of Services to populate a pull-down (rather than native lookup)
    public List<Service__c> SvcTemp = new List<Service__c>();  
    
    public List<SelectOption> SvcList
        {
            get
            {
                SvcTemp = [SELECT id, Name From Service__c WHERE Program__c =: unitOfService.Program__c AND Active__c = true ORDER BY Name];
                SvcList = new List<SelectOption>();
                SvcList.add(new selectOption('', '--None--'));
                for(Service__c temp : SvcTemp)
                {
                    SvcList.add(new SelectOption(temp.Id, temp.Name));
                }
                return SvcList;
            }
            set;
        }
        
    // KI 4/26/2016 Inserted list below for Equipment Loan/Grant drop-down to replace lookup 
    // Declare a list of Equipment Loan/Grant records to populate a pull-down (rather than native lookup)
    public List<Equipment_Loan_Grant__c> eqLGTemp = new List<Equipment_Loan_Grant__c>();  
    
    public List<SelectOption> eqList
        {
            get
            {
                eqLGTemp = [SELECT id, Equipment_Inventory__r.Name, LoanGranted__c, Date_Received__c From Equipment_Loan_Grant__c WHERE Participation__c =: unitOfService.Participant__c ORDER BY Equipment_Inventory__r.Name];
                eqList = new List<SelectOption>();
                eqList.add(new selectOption('', '--None--'));
                for(Equipment_Loan_Grant__c temp : eqLGTemp)
                {
                    eqList.add(new SelectOption(temp.Id, temp.Equipment_Inventory__r.Name + ' (' + temp.LoanGranted__c + ' ' + temp.Date_Received__c.Month() + '/' + temp.Date_Received__c.Day() + '/' + temp.Date_Received__c.Year() + ')' ));
                }
                return eqList;
            }
            set;
        }   
        
        
        
        
        
    // Declare a list of Payment Sources to populate a pull-down (rather than native lookup)
    public List<Payment_Source__c> PmtTemp = new List<Payment_Source__c>();  
    
    public List<SelectOption> PmtList
        {
            get
            {
                PmtTemp = [SELECT id, Name From Payment_Source__c WHERE Active__c = TRUE ORDER BY Name];
                PmtList = new List<SelectOption>();
                PmtList.add(new selectOption('', '--None--'));
                for(Payment_Source__c temp : PmtTemp)
                {
                    PmtList.add(new SelectOption(temp.Id, temp.Name));
                }
                return PmtList;
            }
            set;
        }
    
    public Decimal unitsLeftHidden{get; set;}
    
    public String authMessage{get; set;}
        
    // Lookup units remaining from existing authorization record.
    public Decimal getUnitsRemaining() {
        try {
            Authorization__c exAuth = [SELECT Units_Remaining__c FROM Authorization__c WHERE Id = : unitOfService.Authorization__c];
            Decimal unitsLeftEx = exAuth.Units_Remaining__c; 
            return unitsLeftEx;
        }        
        catch(QueryException exNoAuth)
        {
            system.debug(exNoAuth);
            return null;
        }       
     }
    
    public pageReference save(){    

        // Set field for previewing Progress/Lesson Notes.
        // We're trying to set a TextArea from part of a RichTextArea (html formatted field), so we need to strip html tags out.
        if(unitOfService.Progress_Lesson_Notes__c != '' && unitOfService.Progress_Lesson_Notes__c != NULL ) 
        {
            String txt = unitOfService.Progress_Lesson_Notes__c;
            String txtCleaned = txt.stripHtmlTags();
            Integer len = txtCleaned.length();          
            unitOfService.Progress_Notes_Preview__c = (len > 100) ? txtCleaned.subString(0,100)+'...' : txtCleaned;
        }
        
        
        // Check if we're cloning another record.    
        Id recordId = stdController.getId();
        if(recordId != null && ApexPages.currentPage().getParameters().get('clone') == '1') 
        {

            // Create new UOS and copy the values from the cloned record.
            Unit_of_Service__c clonedUOS = new Unit_of_Service__c();
            
            clonedUOS.Participant__c = unitOfService.Participant__c;
            clonedUOS.Profile__c = unitOfService.Profile__c;
            clonedUOS.Program__c = unitOfService.Program__c;
            clonedUOS.Service_Date__c = unitOfService.Service_Date__c;
            clonedUOS.Service_Provider__c = unitOfService.Service_Provider__c;
            clonedUOS.Authorization__c = unitOfService.Authorization__c;
            clonedUOS.Location_Picklist__c = unitOfService.Location_Picklist__c;
            clonedUOS.Lesson_Location__c = unitOfService.Lesson_Location__c;
            clonedUOS.Client_Travel_Mode__c = unitOfService.Client_Travel_Mode__c;
            clonedUOS.Trainer_Travel_Mode__c = unitOfService.Trainer_Travel_Mode__c;
            clonedUOS.Event_Workshop__c = unitOfService.Event_Workshop__c;
            clonedUOS.Class_Component__c = unitOfService.Class_Component__c;                        
            clonedUOS.Service__c = unitOfService.Service__c;
            clonedUOS.Equipment_Requested__c = unitOfService.Equipment_Requested__c;   
            clonedUOS.Type_of_Equipment_Loaned_Granted__c = unitOfService.Type_of_Equipment_Loaned_Granted__c; 
            clonedUOS.Equipment_Loaned_Granted__c = unitOfService.Equipment_Loaned_Granted__c;
            clonedUOS.Delivery_of_Services__c = unitOfService.Delivery_of_Services__c;
            clonedUOS.Service_Time__c = unitOfService.Service_Time__c;
            clonedUOS.Billable_Units__c = unitOfService.Billable_Units__c;
            clonedUOS.Type_of_Units__c = unitOfService.Type_of_Units__c;
            clonedUOS.Payment_Source__c = unitOfService.Payment_Source__c;
            clonedUOS.Indirect_Client_Mtg_Hours__c = unitOfService.Indirect_Client_Mtg_Hours__c;
            clonedUOS.Travel_Time__c = unitOfService.Travel_Time__c;
            clonedUOS.Cancellation_Reason__c = unitOfService.Cancellation_Reason__c;
            clonedUOS.Progress_Lesson_Notes__c = unitOfService.Progress_Lesson_Notes__c;
            clonedUOS.Progress_Notes_Preview__c = unitOfService.Progress_Notes_Preview__c;
                       
            
            try{
                insert clonedUOS;
                unitOfService.Id = clonedUOS.Id;
                return redirect();   
            }
            catch(Exception e)
            {
                ApexPages.addMessages(e);
                return null;
            }
        }
        else  // Regular save -- no clone.  
        {
               
            try{
                upsert unitOfService; 
                return redirect();
            }
            catch(Exception ex)
            {
                ApexPages.addMessages(ex);
                return null;
            }
        } 
    }
    
    
    public pageReference saveandnew(){    
        try{

            // First invoke save() method above.  This results in the appropriate errors when required fields are left empty, etc.
            // BUT it does not result in errors based on validation rules.
            if(save() == null) {
                return null;
            }
            else {
            
            // Now we need to reconstruct a new URL (with masterid and retURL) for the new record.
            // MasterID is the parent Participation Id.  If we happen to be editing an existing record, masterid is not in the URL -- only the current record ID shows up.
            // In that case above, we set masterid and retURL from participation id that we have our hands on.
            String partID = unitOfService.Participant__c;
            String idString = 'masterid='+partID;
            String pageURL = '/apex/uosNewOrEdit?'+idString+'&retURL=/'+partID;
            PageReference prSaveNew = new PageReference(pageURL);
            prSaveNew.setRedirect(true);
            return prSaveNew;
            }
        } catch(Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            // ApexPages.addMessages(e);
            return null;
        }
        
            
    }
    
    
    public pageReference saveandcopy() {
        
        // 1. Save the current record.
        // 2. Set the URL to the id of the current record with clone=1 in URL.
        // 3. Modify 'Save' to look for clone=1 in URL.  If it's there, then create new UOS, set fields and insert!

        try{
            // First invoke save() method above.
            if(save() == null) {
                return null;
            }
            else {
            
                // Now we need to reconstruct a new URL (with id of record to be cloned and clone=1 and retURL) for the new record.
                String partID = unitOfService.Participant__c;
                String uosID = unitOfService.Id; // We need the id of the newly saved uos record -- not the one that belongs to this controller...  (it's only the first)
                String idString = 'id='+uosID;
                String pageURL = '/apex/uosNewOrEdit?clone=1&'+idString+'&retURL=/'+partID;
                PageReference prSaveCopy = new PageReference(pageURL);
                prSaveCopy.setRedirect(true);
                return prSaveCopy;     
                
            }
        } catch(Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            // ApexPages.addMessages(e);
            return null;
        }
    
    }
    
   
    public pageReference cancel(){    
        PageReference pageRef = stdController.cancel();
        return redirect();
    }  
    
    // This one works -- pulls retURL out of the URL.
    private pageReference redirect() {
    Map<string,string> URLParameters = ApexPages.currentPage().getParameters();
        PageReference pageRef;
        if(URLParameters.containsKey('retURL')){
            pageRef = new PageReference(URLParameters.get('retURL'));
        }   
        pageRef.setRedirect(true);
        return pageRef;
    }
       
           
    // Uses Javascript Remoting to look up authorization record based on 
    // Authorization ID that's passed in as the parameter.
    @RemoteAction
    global static String getAuthString(String authId) {
            try {
                Authorization__c auth = [SELECT Units_Remaining__c, Payment_Source__c, Payment_Source__r.Name FROM Authorization__c WHERE Id = : authId];
                Decimal unitsLeft = auth.Units_Remaining__c;
                String paymntSrcID = auth.Payment_Source__c;
                String paymntSrcName = auth.Payment_Source__r.Name;
                String concatStr = unitsLeft + '||' + paymntSrcID + '||' + paymntSrcName;
                return concatStr;
            } 
            catch(QueryException exNoAuthRemote)
            {
                system.debug(exNoAuthRemote);
                return '0';
                // Pretty much ensured that authorization exists since it was based on query results. Picklist rather than lookup field that can be manually typed into.
            }  

    }
}