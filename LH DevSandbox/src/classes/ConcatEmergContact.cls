public with sharing class ConcatEmergContact {


	public static void UpdateProfileEC (Set<Id> prIds)
	{

		// Retrieve Profiles to update
		List<Profile__c> prList = new List<Profile__c> (
		[SELECT Id, Emergency_Contacts_Abbreviated__c, Name,
         	(SELECT Id, Relationship__c, PrimaryPhone__c, SecondaryPhone__c, Email__c, Comments__c, Name, Profile__r.Id FROM Emergency_Contacts__r)
         FROM Profile__c WHERE Id IN : prIds]); 

		String concatTxt;
		String rel;
		String phones;
        String eml;
		String cmts;
		List<Profile__c> prToUpdate = new List<Profile__c>();
        
        // Check out Profiles in RecordCheckout for editing.
        Map<Id, Record_Checkout__c> chPrMap = RecordMaintenance.CheckoutRecords(prIds);
        
        Set<Id> prIdsToQueue = new Set<Id>();
        Set<Id> prIdsToCheckIn = new Set<Id>();
        String userid = UserInfo.getUserId();
        
        // For each profile in profile list concatenate emergency contacts for that profile (using child relationship name: Emergency_Contacts__r.

		for (Profile__c thisPR : prList) {
            if (thisPR.Emergency_Contacts__r.size() > 0) {
				for (EmergencyContact__c thisEC : thisPR.Emergency_Contacts__r) {
                    if (thisEC.Id != null && thisEC.Profile__r.Id == thisPR.Id) {
						rel = (thisEC.Relationship__c != null ) ? ' (' + thisEC.Relationship__c + ')' : '';
						if (thisEC.PrimaryPhone__c != null && thisEC.SecondaryPhone__c != null) {
							phones = ' ' + thisEC.PrimaryPhone__c + '; ' + thisEC.SecondaryPhone__c;
						} else if (thisEC.PrimaryPhone__c != null) {
							phones = ' ' + thisEC.PrimaryPhone__c;
						} else if (thisEC.SecondaryPhone__c != null) {
							phones = ' ' + thisEC.SecondaryPhone__c;
                        } else {
                            phones = '';
                        }
                    	eml = ( thisEC.Email__c != null ) ? ' ' + thisEC.Email__c : '';
            			cmts = ( thisEC.Comments__c != null ) ? ' Comments: ' + thisEC.Comments__c : '';
            			concatTxt = ((concatTxt == null) ? '' : concatTxt + '\r\n' ) + thisEC.Name + rel + ':' + phones + eml + cmts;
                        // Reset variables
                        rel = '';
                        phones = '';
                        eml = '';
                        cmts = '';
                    }
            	}           
            } else {
                concatTxt = '';
            }
            String txt = concatTxt;
            String txtCleaned = txt.stripHtmlTags();
            Integer len = txtCleaned.length();   
            String concatExcerpt = (len > 255) ? txtCleaned.subString(0,252)+'...' : txtCleaned;
			thisPR.Emergency_Contacts_Abbreviated__c = concatExcerpt.trim();
            
            // Retrieve RecordCheckout to see if this record is locked for editing.
        	Record_Checkout__c rcThisProf = chPrMap.get(thisPR.Id);
            
            if ( rcThisProf.User__c == userid || rcThisProf.User__c == null)
            {
            	// Record successfully checked out for updating.
            	prToUpdate.add (thisPR);
                prIdsToCheckIn.add(thisPR.Id);
            }
            else
            {
                // Record locked for editing.  Add to queue to update during nightly batch.
                prIdsToQueue.add(thisPR.Id);
            }
            
            // Reset concat var
            concatTxt = '';
		}
	
		if (prToUpdate.size() > 0)
    	{

        	// Update Profiles that we've checked out and then check them back in.
        	update prToUpdate;
        	RecordMaintenance.CheckinRecords(prIdsToCheckIn);
    	}
        
		// Queue locked records for updating during batch update.
    	if ( prIdsToQueue.size() > 0 ) RecordMaintenance.QueueForProfileUpdate(prIdsToQueue);  
    
    } 


}