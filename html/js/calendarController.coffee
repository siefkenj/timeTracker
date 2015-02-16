app = angular.module 'App', []

app.controller( 'Calendar' , [
    '$scope'
    ( $scope ) ->
        locale = 'en-us'
        # get the current day of the month
        now = new Date()
        #setup the month to be the month that is displayed
        year = now.getFullYear()
        month = now.getMonth() + 4
        displayMonth = new Date year, month, 1

        # make the text name visible to the controller
        $scope.month = displayMonth.toLocaleDateString( locale, {month:'long'} )

        #now setup the month to be displayed properly
        firstDay = displayMonth.getDay()
        numDays = (new Date( year, month+1, 0)).getDate()
        for elm, index in document.querySelectorAll('.day')
            if index < firstDay || index > numDays
                elm.innerHTML = ''
            else
                elm.innerHTML = index - firstDay + 1
        return 
])
