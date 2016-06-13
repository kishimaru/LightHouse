public with sharing class UOSUpdateAuthViaRollup {
    
    // NOTE: This utilizes code posted on GitHub that does rollup summaries on lookups.
    // I haven't been able to test successfully -- i get attempt to dereference a null object 
    // when I try to add a deleted or updated record using: objects.add(uosbeforeUpdate)
    
    // The method takes an Sobject array (what I think is an array): Unit_of_Service[]
    // Inside my loop of the trigger records, I'm adding records to the array a la: objects.add(uosbeforeUpdate);
    // And call the class like this: UOSUpdateAuthViaRollup.UpdateAuth(objects);
    // But I can't get beyond the errors so am going to bail and iterate through the records to sum.

    public static void UpdateAuth (Sobject[] uosrec) 
    {
        
		/*
		Using LREngine class from github:
		First step is to create a context for LREngine, by specifying parent and child objects and
      	lookup relationship field name
     	*/
		LREngine.Context ctx = new LREngine.Context(Authorization__c.SobjectType, // parent object
                                            Unit_of_Service__c.SobjectType,  // child object
                                            Schema.SObjectType.Unit_of_Service__c.fields.Authorization__c // relationship field name
                                            );    
        
        /*
      	Next, one can add multiple rollup fields on the above relationship. 
      	Here specify 
       	1. The field to aggregate in child object
       	2. The field to which aggregated value will be saved in master/parent object
       	3. The aggregate operation to be done i.e. SUM, AVG, COUNT, MIN/MAX
     	*/
     	ctx.add(
            new LREngine.RollupSummaryField(
                                            Schema.SObjectType.Authorization__c.fields.Units_of_Service_Provided__c,
                                            Schema.SObjectType.Unit_of_Service__c.fields.Billable_Units__c,
                                            LREngine.RollupOperation.Sum 
                                         )); 
        
        /* 
      	Calling rollup method returns in memory master objects with aggregated values in them. 
      	Note these master records are not persisted back, so that client gets a chance 
      	to post process them after rollup
      	*/ 
     	Sobject[] parentAuth = LREngine.rollUp(ctx, uosrec);    
        
        update parentAuth;     
        
    }
        
        
        
        
    
}