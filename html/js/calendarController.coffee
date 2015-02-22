setupMonth = ( displayMonth ) ->
    year = displayMonth.getFullYear()
    month = displayMonth.getMonth()
    #now setup the month to be displayed properly
    firstDay = displayMonth.getDay()
    
    lastMonth = ( (new Date( year, month, -x )).getDate() for x in [0 ... firstDay] ).reverse()

    numDays = (new Date( year, month+1, 0)).getDate()
    thisMonth = ( x for x in [1 .. numDays ] )

    remainingDays = (7 - (numDays + firstDay) %% 7) %% 7
    nextMonth = ( x + 1 for x in [0 ... remainingDays ]  )

    console.log( lastMonth, firstDay )
    console.log( thisMonth, numDays )
    console.log( nextMonth, numDays + firstDay, remainingDays )
    displayDays= lastMonth.concat thisMonth.concat nextMonth
    result = []
    week = []
    for day, index in displayDays
        week.push(day)
        console.log( index , day, (index + 1) % 7)
        if !( (index+1) % 7 )
            result.push(week)
            week = []
    console.log(result)

    return result

app = angular.module 'App', []

app.controller( 'Calendar' , [
    '$scope',
    ( $scope ) ->
        locale = 'en-us'
        # get the current day of the month
        now = new Date()
        #setup the month to be the month that is displayed
        year = now.getFullYear()
        month = now.getMonth()

        #month numbers visible to the screen!!
        $scope.monthNum = month
        $scope.yearNum = year

        # make the text name visible to the controller
        $scope.month = ->
            date = new Date($scope.yearNum, $scope.monthNum,1 )
            return date.toLocaleDateString( locale, {month:'long'} )
        $scope.date = ( year, month ) ->
            return new Date( year, month, 1)
        
        $scope.displayDays = ->
            setupMonth( $scope.date($scope.yearNum, $scope.monthNum) )

        return
]).directive(
    'monthView'
    () ->
        return{

        }
)
