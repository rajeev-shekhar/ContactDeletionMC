/*Author: Rajeev Shekhar
 *API call towards MC to delete data
*/

public class sb_MC_Authentication {
    
    //Getting the existing session ID
    public static sb_Marketing_Cloud_Crendential__c getOldSessionID() { 
        sb_Marketing_Cloud_Crendential__c[] session = getCredentials();
        if(session.size() > 0) {
            return session[0];
        } else {
            return null;
        }
    }
    
    //Creating a new session ID
    public static String createNewSession() {
        sb_Marketing_Cloud_Crendential__c[] creds = getCredentials();
        String sessionID = null;
        if(creds.size() > 0) {
            System.JSONGenerator gen = JSON.createGenerator(false);
            gen.writeStartObject();
            gen.writeStringField('clientId', creds[0].sb_ClientID__c);
            gen.writeStringField('clientSecret', creds[0].sb_Client_Secret__c);
            gen.writeEndObject();
            gen.close();
            String body = gen.getAsString();
            
            HttpRequest req = new HttpRequest();
            req.setEndPoint(creds[0].sb_Access_Token_URL__c);
            req.setBody(body);
            req.setHeader('Content-Type','application/json');
            req.setMethod('POST');
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            if(res.getStatusCode() == 200 && res.getStatus() == 'OK') {
                Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                sessionID = (String) m.get('accessToken');
            }        
        }
      return sessionID;  
    }
    
    //Return the credential record
    public static sb_Marketing_Cloud_Crendential__c[] getCredentials() {
        return [SELECT Id, Name, sb_Access_Token_URL__c, sb_API_Endpoint__c, sb_ClientID__c, sb_Client_Secret__c, sb_SessionID__c 
                FROM sb_Marketing_Cloud_Crendential__c WHERE Name = 'Sbanken_MC' LIMIT 1];
    }
    
    //Update credentials
    public static void updateCredentials(String sessionID) {
        sb_Marketing_Cloud_Crendential__c[] credentials = getCredentials();
        credentials[0].sb_SessionID__c = sessionID;
        update credentials;
    }
}