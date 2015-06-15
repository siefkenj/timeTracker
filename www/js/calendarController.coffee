###
# Here we define all controllers relavent to the calendar view
###
app = angular.module('calendarControllers', [])

###
# CalendarController
###
LOCALE = "en-us"
calendarController = ($scope, $http, $routeParams, dataService) ->
    # the calendar defaults to show the current month
    now = new Date()
    # get the month and year from the url or use todays date
    $scope.monthNum = ($routeParams.month - 1)|0 ||  now.getMonth()
    $scope.yearNum = $routeParams.year|0 ||  now.getFullYear()

    window.ss=$scope
    $scope.monthToString = (m) ->
        return (new Date($scope.yearNum, m)).toLocaleDateString(LOCALE, {month: 'long'})
    $scope.monthList = [0...12]

    $scope.incMonth = (inc) ->
        $scope.monthNum += inc

    $scope.monthName = ->
        # returns the text of the current month
        nav = window.navigator
        locale = nav.language || nav.userLanguage
        date = new Date $scope.yearNum, $scope.monthNum, 1
        return date.toLocaleDateString locale, {month: 'long'}

    $scope.$watch 'monthNum', ->
        # this is run every time monthNum changes so it it necessary to
        # use the scopes year and month as the month will vary
        newDate = new Date $scope.yearNum, $scope.monthNum, 1
        # display days is an array of objects representing the calendar data
        $scope.displayDays = setupMonth newDate, dataService
    return

setupMonth = (displayMonth, dataService) ->
    # returns an array of arrays representing the current month
    getDate = (date) ->
        # generates an object with the time information of the specified date
        ret =
            jsDate: date
            date: date.getDate()
            data: null
        dataService.get(ret.jsDate)
            .then (dayData) ->
                ret.data = dayData
        return ret

    year = displayMonth.getFullYear()
    month = displayMonth.getMonth()
    #first day of the week 0 = sunday 6 = saturday
    firstDay = displayMonth.getDay()

    # make and array for the days of last month that are to be displayed
    # i.e if this month starts on tuesday, find the dates of sunday and
    # monday of last month
    lastMonth = (getDate(new Date year, month, -x) for x in [0 ... firstDay]).reverse()

    # make an array for the days of the current month
    # find the total number of days in the current month
    numDays = (new Date year, month+1, 0).getDate()
    thisMonth = (getDate(new Date year, month, x) for x in [1 ... numDays ])

    # find the number of days from the end of the current month
    # to the end of the calendar week
    # i.e. this month ends on a thursday so there are 2 days remaining
    remainingDays = 7 - (new Date year, month+1, 0).getDay()
    nextMonth = (getDate(new Date year, month+1, x+1 ) for x in [0 ... remainingDays ])

    # make one big array of all the days that are being displayed
    displayDays = lastMonth.concat thisMonth.concat nextMonth

    result = []
    week = []
    # build and array of 7 element arrays representing
    for day, index in displayDays
        week.push(day)
        if !((index+1) % 7)
            result.push(week)
            week = []
    return result

app.controller('CalendarController', [
    '$scope',
    '$http',
    '$routeParams',
    'dataService',
    calendarController])

calendarDayWidget = ->
    templateUrl: 'templates/calendar_day_widget.html'
    restrict: 'E'
    scope:
        day: "=day"

app.directive('calendarDayWidget', calendarDayWidget)
