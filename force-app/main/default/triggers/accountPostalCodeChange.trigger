trigger accountPostalCodeChange on Account (before update) {
    String operationType = 'UpdatePostalCode';
    switch on operationType {
        when 'UpdatePostalCode' {
            // Handle postal code change
            AccountPostalCodeChangeHandler.handleChange(Trigger.new, Trigger.oldMap);
        }
        when else {
            System.debug('Unexpected operation type for Account trigger: ' + operationType);
        }
    }
}