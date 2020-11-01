/*Author: Rajeev Shekhar
 *API call towards MC to delete data
*/

public with sharing class sb_deleteContactsInMC {
    
    @future(callout=true)
    public static void deleteContacts(List<Id> Ids) {
        //Creating request
        System.JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeNumberField('ContactTypeId',2);
        gen.writeObjectField('values',ids);
        gen.writeStringField('DeleteOperationType', 'ContactAndAttributes');
        gen.writeEndObject();
        gen.close();
        String body = gen.getAsString();
        
        //Getting the existing session info
        sb_Marketing_Cloud_Crendential__c credentials = sb_MC_Authentication.getOldSessionID();
        
        if(credentials != null) {
        //Callout
        HttpResponse res = makeCallout(credentials,body);        

        //Verification
        if(res.getStatusCode() == 401 && res.getStatus() == 'Unauthorized') {
            String newSessionID = sb_MC_Authentication.createNewSession();
            //Callout again
            HttpResponse resV2 = makeCallout(credentials,body,newSessionID);
            if(resV2.getStatusCode() == 200 && resV2.getStatus() == 'OK') {
                sb_MC_Authentication.updateCredentials(newSessionID);
                createDeleteLog(resV2,Ids);
            } else {
                sb_MC_Authentication.updateCredentials(newSessionID);
            } 
        } else if(res.getStatusCode() == 200 && res.getStatus() == 'OK') {
              createDeleteLog(res,Ids);
        }
      }          
    }
    
    //Initiate callout
    private static HttpResponse makeCallout(sb_Marketing_Cloud_Crendential__c credentials, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndPoint(credentials.sb_API_Endpoint__c);
        req.setBody(body);
        req.setHeader('Content-Type','application/json');
        req.setHeader('Authorization','Bearer ' + credentials.sb_SessionID__c);
        req.setMethod('POST');
        Http http = new Http();
        HTTPResponse response = http.send(req);
       return response; 
    }
    
    //Initiate callout
    private static HttpResponse makeCallout(sb_Marketing_Cloud_Crendential__c credentials, String body, String sessionID) {
        HttpRequest req = new HttpRequest();
        req.setEndPoint(credentials.sb_API_Endpoint__c);
        req.setBody(body);
        req.setHeader('Content-Type','application/json');
        req.setHeader('Authorization','Bearer ' + sessionID);
        req.setMethod('POST');
        Http http = new Http();
        HTTPResponse response = http.send(req);
       return response; 
    }
    
    //Create delete log
    private static void createDeleteLog(HttpResponse response, List<Id> Ids) {
        //Getting params
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        
        //Creating logs
        sb_Marketing_Cloud_Contact_Delete_Log__c log = new sb_Marketing_Cloud_Contact_Delete_Log__c();
        log.sb_Initiated_By_User__c = UserInfo.getName();
        log.sb_Initiated_By_UserID__c = UserInfo.getUserId();
        log.sb_OperationID__c =  (Integer) params.get('operationID');
        log.sb_Operation_Initiated__c = (Boolean) params.get('operationInitiated');
        log.sb_Record_Count__c = Ids.size();
        log.sb_Request_Service_MessageID__c = (String) params.get('requestServiceMessageID');
        log.sb_Service_MessageID__c = (String) params.get('serviceMessageID');
        log.sb_Timestamp__c = Datetime.now();
        log.sb_Deleted_Record_IDs__c = String.Join(Ids,',');
        insert log;
    }
}