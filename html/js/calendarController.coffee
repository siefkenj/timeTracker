# returns an array of 7 object arrays representing the current display month
setupMonth = (displayMonth, dataService) ->
    year = displayMonth.getFullYear()
    month = displayMonth.getMonth()
    # first day is the first day of the week 0 = sunday 6 = saturday
    firstDay = displayMonth.getDay()

    # generates an object with the tracking information of the date
    makeDate = (date) ->
        ret =
            jsDate: date
            date: date.getDate()
            data: null
        dataService.get(ret.jsDate)
            .then (dayData) ->
                ret.data = dayData
        return ret

    lastMonth = (makeDate(new Date(year, month, -x)) for x in [0 ... firstDay]).reverse()

    # find the total number of days in the current month
    numDays = (new Date( year, month+1, 0)).getDate()
    thisMonth = (makeDate(new Date(year, month, x)) for x in [1 .. numDays ])

    # find the number of days from the end of the current month to the end of the calendar week
    remainingDays = (7 - (numDays + firstDay) %% 7) %% 7
    nextMonth = (makeDate(new Date(year, month + 1, x + 1 )) for x in [0 ... remainingDays ])

    # make one big array of all the days that are being displayed
    displayDays = lastMonth.concat thisMonth.concat nextMonth
    result = []
    # build and array of 7 element arrays representing the days that are to be displayed in the
    # calendar
    week = []
    for day, index in displayDays
        week.push(day)
        if !((index+1) % 7)
            result.push(week)
            week = []
    return result

app = angular.module('calendarControllers', [])

calendarController = ($scope, $http, dataService, $routeParams) ->
    # the calendar defaults to show the current month
    now = new Date()
    $scope.monthNum = ($routeParams.month - 1)|0 ||  now.getMonth()
    $scope.yearNum = $routeParams.year|0 ||  now.getFullYear()

    $scope.incMonth = (inc) ->
        console.log inc
        $scope.monthNum += inc

    # make the text name visible to the controller
    $scope.monthName = ->
        locale = 'en-us'
        date = new Date($scope.yearNum, $scope.monthNum, 1)
        return date.toLocaleDateString(locale, {month: 'long'})

    $scope.$watch 'monthNum', ->
        # display days is an array of object representing the calendar data
        $scope.displayDays = setupMonth(
            # this is run every time monthNum changes so it it necessary to
            # use the scopes year and month as the month will vary
            new Date($scope.yearNum, $scope.monthNum, 1),
            dataService
        )
    return

app.controller('Calendar', ['$scope', '$http', 'dataService', '$routeParams', calendarController])

calendarDayWidget = ->
    templateUrl: 'templates/calendar_day_widget.html'
    restrict: 'E'
    scope:
        day: "=day"

app.directive('calendarDayWidget', calendarDayWidget)
