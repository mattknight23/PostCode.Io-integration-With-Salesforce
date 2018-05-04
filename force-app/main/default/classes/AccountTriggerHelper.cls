public with sharing class AccountTriggerHelper {


    public static void extractPostcodes(List<Account> accounts) {
        Map<String, List<Account>> postCodeAccountMap = buildPostCodeAccountMap(accounts);
        Set<Id> accountIds = new Set<Id>();
        Set<String> postCodes = postCodeAccountMap.keyset();
        for(Account a : accounts) {
            accountIds.add(a.Id);
        
        }
        sendPostCodes(postCodes, accountIds);
    }

    private static Map<String, List<Account>> buildPostCodeAccountMap(List<Account> accounts) {

        Map<String, List<Account>> postCodeAccounts = new Map<String, List<Account>>();

        for(Account acc : accounts) {
            
            acc.BillingLongitude = null;
            acc.BillingLatitude = null;

            if(!postCodeAccounts.containsKey(acc.BillingPostalCode)){
                postCodeAccounts.put(acc.BillingPostalCode, new List<Account>());
            }
            List<Account> accList = postCodeAccounts.get(acc.BillingPostalCode);
            accList.add(acc);
            postCodeAccounts.put(acc.BillingPostalCode, accList);
        }
        
        return postCodeAccounts;
    }

    @future(callout=true)
    public static void sendPostCodes(Set<String> postCodes, Set<Id> accountIds) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.postcodes.io/postcodes');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"postcodes":'+ JSON.serialize(postcodes) +'}');
        HTTPResponse res = null;
        system.debug(req.getBody());
        try {
            res = http.send(req);
        } catch(Exception e) {
            System.debug('Failed to Post Request: ' + e.getMessage());
        } 

        ResultObject responseHeaderWrapper = null;

        try {
            responseHeaderWrapper = (ResultObject) JSON.deserialize(res.getBody(), ResultObject.class);
        } catch(Exception e) {
            System.debug('Failed to get Response: ' + e.getMessage());
        }

        if(responseHeaderWrapper != null && responseHeaderWrapper.hasSuccess()) {
            List<Account> accountsToUpdate =    [SELECT Id
                                                    , BillingPostalCode
                                                    , BillingLatitude
                                                    , BillingLongitude 
                                                FROM Account 
                                                WHERE BillingPostalCode 
                                                IN: postCodes AND Id 
                                                IN: accountIds 
                                                LIMIT 100];

           Map<String, List<Account>> postCodeAccountMap = buildPostCodeAccountMap(accountsToUpdate);

            for(ResultHeader r : responseHeaderWrapper.result) {
                system.debug(r);
                for(Account acc : postCodeAccountMap.get(r.query)) {
                    acc.BillingLatitude = r.result.latitude;
                    acc.BillingLongitude = r.result.longitude;
                }
            }
        update accountsToUpdate;
        }
    }

    public class ResultObject {
        public Integer status {get; set;}
        public ResultHeader[] result {get; set;}
 
        public Boolean hasSuccess() {
            return status == 200;
        }

    }

    public class ResultHeader {
        public String query {get; set;}  // postcode
        public Results result {get; set;}
    }

    public class Results {
        public Decimal longitude {get; set;}
        public Decimal latitude {get; set;}
    }
}