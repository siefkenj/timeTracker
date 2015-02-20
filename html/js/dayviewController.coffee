
###
# Helper Functions
###

# round to the nearest .5
roundToHalf = (t) ->
    return Math.round(2*t)/2

# creates a list with {thisday: <is ti the current day>, hour: <current hour>}
# with 0 = 12AM current day
createHourList = (start=-2, end=24+4) ->
    today = (t) -> if 0 <= i <= 24 then "today" else "not-today"
    hour = (t) -> "#{if t %% 12 == 0 then 12 else (t%%12)}#{if t %% 24 >=12 then 'pm' else 'am'}"
    return ({thisday: today(i), hour: hour(i)} for i in [start...end])

# take in a person object and return the total number of hours spent that day
getTotalHours = (p) ->
    total = 0
    for t in p.times
        total += t.end - t.start
    return total
# turn a time range into some classes
timeRangeToClassName = (t) ->
    formatNum = (x) ->
        if x %% 1 > 0
            return "#{Math.floor(x)}-5"
        else
            return "#{Math.floor(x)}-0"

    len = roundToHalf(t.end-t.start)
    start = roundToHalf(t.start)
    return "length-#{formatNum(len)} start-#{formatNum(start)}"


START_TIME = -2
END_TIME = 24 + 3

###
# START OF THE APP
###
app = angular.module('App', [])


###
# TimeViewController
###
timeviewController = ($scope) ->
    $scope.people =
        person1:
            name: 'Andrei'
            times: [{start: 7, end: 14}, {start: 22, end: 26}]
        person2:
            name: 'Jonah'
            times: [{start: 16, end: 18.5}]
    $scope.getTotalHours = getTotalHours
    $scope.timeRangeToClassName = timeRangeToClassName

    $scope.hours = createHourList(START_TIME, END_TIME)
    $scope.names = ("#{v.name} (#{getTotalHours(v)})" for k,v of $scope.people)
    console.log $scope.names,$scope.people
    #$scope.hours = ["abc", "123"]

app.controller('TimeViewController', ['$scope', timeviewController])


