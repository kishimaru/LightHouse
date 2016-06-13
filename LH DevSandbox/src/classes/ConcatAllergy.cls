public with sharing class ConcatAllergy {

    public static void UpdateProfileAL (Set<Id> prIds)
	{

		// Retrieve Profiles to update
		List<Profile__c> prList = new List<Profile__c> (
		[SELECT Id, Allergies_Abbreviated__c,
         	(SELECT Allergic_Reaction_and_Treatment__c, Airborne_Environmental__c, Type__c, Comments__c, Name FROM Allergies__r)
         FROM Profile__c WHERE Id IN : prIds]); 

		String concatTxt;
		String type;
        String reaction;
		String cmts;
        String airborne;
		List<Profile__c> prToUpdate = new List<Profile__c>();
        
        // Check out Profiles in RecordCheckout for editing.
        Map<Id, Record_Checkout__c> chPrMap = RecordMaintenance.CheckoutRecords(prIds);
        
        Set<Id> prIdsToQueue = new Set<Id>();
        Set<Id> prIdsToCheckIn = new Set<Id>();
        String userid = UserInfo.getUserId();
	
		// For each profile in profile list concatenate allergies for that profile (using child relationship name: Allergies__r.
	
		for (Profile__c thisPR : prList) {
            if (thisPR.Allergies__r.size() > 0) {
				for (Allergy__c thisAL : thisPR.Allergies__r) {
                    if (thisAL.Id != null) {
                        airborne = (thisAL.Airborne_Environmental__c != null && thisAL.Airborne_Environmental__c == TRUE) ? '- Airborne/Environmental' : '';
                        type = (thisAL.Type__c != null) ? ' (' + thisAL.Type__c + ' allergy' + airborne + ')' : ''; 
                        reaction = (thisAL.Allergic_Reaction_and_Treatment__c != null) ? ' Reaction/Treatment: ' + thisAL.Allergic_Reaction_and_Treatment__c + ';' : '';
            			cmts = (thisAL.Comments__c != null) ? ' Comments: ' + thisAL.Comments__c : '';
            			concatTxt = ((concatTxt == null) ? '' : concatTxt + '\r\n' ) + thisAL.Name + type + ' -' + reaction + cmts;
                        // Reset variables
                        type = '';
                        reaction = '';
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
			thisPR.Allergies_Abbreviated__c = concatExcerpt.trim();
                    	
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
            

            concatTxt = ''; // reset!
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