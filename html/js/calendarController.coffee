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

        $scope.$watch('month', $scope.date)
        return
]).directive(
    'monthView'
    () ->
        return{
            scope:
                yearNum: '='
                monthNum: '='
            link: (scope, element, attrs) ->
                scope.$watch('monthNum', ->
                    setupMonth(new Date(scope.yearNum,scope.monthNum,1))
                )
                window.xx = scope
                console.log(scope)
                console.log( scope.yearNum, scope.monthNum  )
                #console.log(scope.datex())
                setupMonth = ( displayMonth ) ->
                    year = displayMonth.getFullYear()
                    month = displayMonth.getMonth()
                    #now setup the month to be displayed properly
                    firstDay = displayMonth.getDay()

                    numDays = (new Date( year, month+1, 0)).getDate()
                    for elm, index in document.querySelectorAll('.day')
                        if index < firstDay || index > numDays+firstDay-1
                            elm.innerHTML = ''
                        else
                            elm.innerHTML = index - firstDay + 1
                #setupMonth( scope.datex() )
                setupMonth(new Date(scope.$parent.yearNum,scope.$parent.monthNum,1))
        }
)
