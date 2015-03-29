
###
# Helper Functions
###




START_TIME = -2
END_TIME = 24 + 3


###
# START OF THE APP
###
app = angular.module('App', ['ngRoute', 'calendarControllers', 'dayviewControllers'])


###
# MainController
###
mainController = ($scope, $routeParams, $location) ->
    $scope.people =
        person1:
            name: 'Andrei'
            times: [{start: 7, end: 14}, {start: 22, end: 26}]
        person2:
            name: 'Jonah'
            times: [{start: 16, end: 18.5}]
    #$scope.getTotalHours = getTotalHours
    #$scope.timeRangeToClassName = timeRangeToClassName
    #$scope.formatName = formatName

    #$scope.hours = createHourList(START_TIME, END_TIME)
    #console.log $scope.people
    
    $scope.showCalendar = ->
        $location.url('/calendar')
        console.log 'cal'
    $scope.showDay = ->
        $location.url('/day')
        console.log 'day'

    console.log $routeParams
    $scope.abc = $routeParams.id || "default"

    # set up even listeners to see if we've clicked
    # and want to add a new time for someone

    return
app.controller('MainController', ['$scope', '$routeParams', '$location', mainController])

app.config(['$routeProvider',
    ($routeProvider) ->
        $routeProvider.when('/calendar', {templateUrl: 'calendar-template.html', controller: 'Calendar'})
            .when('/day', {templateUrl: 'dayview-template.html', controller: 'TimeViewController'})
            .when('/day/:year/:month/:day', {templateUrl: 'dayview-template.html', controller: 'TimeViewController'})
            .otherwise({redirectTo: '/calendar'})
    ])
