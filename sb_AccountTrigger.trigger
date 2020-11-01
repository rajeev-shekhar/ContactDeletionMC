/*Author: Rajeev Shekhar
 *API call towards MC to delete data
*/

trigger sb_AccountTrigger on Account (after delete) {
    List<Id> ids = new List<Id>();
    for(Account a : trigger.old) ids.add(a.PersonContactId);
    sb_Environment_Settings__c mc = sb_Environment_Settings__c.getInstance();
    if(mc.sb_MC_Account_Delete_API__c && ids.size() > 0) sb_deleteContactsInMC.deleteContacts(ids);    
}