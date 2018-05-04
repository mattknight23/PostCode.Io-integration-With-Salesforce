trigger AccountTrigger on Account (before update) {

    AccountTriggerHandler handler = new AccountTriggerHandler();

    if((trigger.isUpdate && trigger.isBefore) || (trigger.isBefore && trigger.isInsert)) {
        handler.beforeInsertUpdate(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
    }
}