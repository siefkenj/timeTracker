app = angular.module 'App', []

app.controller( 'Calendar' , [
    '$scope'
    ( $scope ) ->
        locale = 'en-us'
        now = new Date()
        year = now.getFullYear()
        $scope.month = now.toLocaleDateString( locale, {month:'long'} )
        displayMonth = new Date year, month, 1
        firstDay = displayMonth.getDay()
        return
])
