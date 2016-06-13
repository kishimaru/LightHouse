public class AttendanceTrackingFormQueryService {
    
    public static List<Unit_of_Service__c> queryUosForClassComponent(Id classId) {
        return [Select Id, Service_Provider__c, Name, Participant__c, Participant__r.Name, 
                        Service_Date__c, Service_Time__c, Number_of_Additional_People__c, Cancellation_Reason__c, 
                        Billable_Units__c, Type_of_Units__c, Payment_Source__c, Authorization__c, Progress_Lesson_Notes__c from Unit_of_Service__c 
                        where Class_Component__c = :classId order by Participant__r.Name];
        
    }
    
    public static List<Participation__c> queryProgramParticipants(Id workshopId) {
        return [Select Id, Name from Participation__c where Program__c in 
         (Select Program__c  from Event_Workshop__c where Id = :workshopId)
         AND Status__c != 'Closed'];
        
    }

    public static List<Participation__c> queryClassParticipants(Id workshopId) {
        return [Select Id, Name from Participation__c where Id in 
         (Select Participant__c  from Enrollment__c where Event_Workshop__c = :workshopId)
         AND Status__c != 'Closed'];      
    }
    
    public static List<Payment_Source__c> queryPaymentSources() {
        return [Select Id, Name from Payment_Source__c where Active__c = true order by Name];
    }
    
    public static List<Authorization__c> queryAuthorizations(Set<String> participantIds) {
        return [Select Id, Name, Participation__c  from Authorization__c where Participation__c in :participantIds];
    }
    
    public static List<Event_Workshop__c> queryWorkshops() {
        return [Select Id, Name from Event_Workshop__c where Active__c = true];        
    }
    
    public static Event_Workshop__c queryWorkshop(String workshopId) {
        return [Select Id, Name, Program__c from Event_Workshop__c where Id = :workshopId];
    }
    
    // KI added Location_Picklist__c 4/22/2016 (to auto-populate Location in UOS based on Location in Class/Component).
    public static Class_Component__c queryClassComponent(String classId) {
        return [Select Id, Name, Begin_Datetime__c, Hours__c, Service__c, Service_Provider__c, Location_Picklist__c from Class_Component__c where Id = :classId];
    }
    
    public static List<User> queryServiceProviders() {
        return [Select Id, Name from User where IsActive = true];
    }
    
    public static List<Class_Component__c> queryClassComponentsForWorkshop(Id workshopId) {
        return [Select Id, Name, Service_Provider__c from Class_Component__c where Event_Workshop__c = :workshopId order by Begin_Datetime__c];
    }

}