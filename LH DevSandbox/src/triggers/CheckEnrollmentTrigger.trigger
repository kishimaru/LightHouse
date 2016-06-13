trigger CheckEnrollmentTrigger on Unit_of_Service__c (after insert) {
    List<String> participantIds = new List<String>();
    List<String> classComponentIds = new List<String>();
    
    Map<String, Unit_of_Service__c> comboIdsToUosIdMap = new Map<String, Unit_of_Service__c>();
    for (Unit_Of_Service__c uos: Trigger.new) {
        if (uos.Class_Component__c != null) {
            comboIdsToUosIdMap.put(uos.Participant__c + '_' + uos.Class_Component__c, uos);
            participantIds.add(uos.Participant__c);
            classComponentIds.add(uos.Class_Component__c);
        }
    }
    
    if (comboIdsToUosIdMap.size() > 0) {
        List<Enrollment__c> enrollments = [Select Id, Class_Component__c, Participant__c 
         from Enrollment__c 
         where Participant__c in :participantIds
         or Class_Component__c in :classComponentIds
        ];
        for (Enrollment__c enrollment: enrollments) {
            String key = enrollment.Participant__c + '_' + enrollment.Class_Component__c;
            if (comboIdsToUosIdMap.containsKey(key)) {
                comboIdsToUosIdMap.remove(key);
            }
        }
    }
    
    if (comboIdsToUosIdMap.size() > 0) {
        List<Enrollment__c> enrollmentsToInsert = new List<Enrollment__c>();
        for (String comboId: comboIdsToUosIdMap.keySet()) {
            Unit_of_Service__c uos = comboIdsToUosIdMap.get(comboId);
            
            enrollmentsToInsert.add(new Enrollment__c(
                Participant__c = uos.Participant__c,
                Class_Component__c = uos.Class_Component__c,
                Event_Workshop__c = uos.Event_Workshop__c
            ));
        }
        insert enrollmentsToInsert;
    }
}