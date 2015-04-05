
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
    #$scope.getTotalHours = getTotalHours
    #$scope.timeRangeToClassName = timeRangeToClassName
    #$scope.formatName = formatName

    #$scope.hours = createHourList(START_TIME, END_TIME)
    #console.log $scope.people

    $scope.showCalendar = ->
        $location.url('/calendar')
        console.log 'cal'
        return
    $scope.showDay = (date) ->
        $location.url("/day/#{date[0]}/#{date[1]+1}/#{date[2]}")
        console.log 'day', date
        return

    console.log $routeParams
    $scope.abc = $routeParams.id || "default"

    # set up even listeners to see if we've clicked
    # and want to add a new time for someone

    return
app.controller('MainController', ['$scope', '$routeParams', '$location', mainController])

# create a service that will handle access to all of our data
dataService = ($http, $q) ->
    # set up a promise that will deliver all the data
    deferred = $q.defer()
    success = (response) ->
        deferred.resolve(response)
    failure = (response) ->
        deferred.reject(response)
    $http.get("js/test-hangout-data.json").success(success).error(failure)
    data = deferred.promise
        
    ret =
        get: (year, month, day) ->
            if year instanceof Date
                day = year.getDate()
                month = year.getMonth() + 1
                year = year.getFullYear()
            date = new Date(year, month - 1, day)

            # return a promise that gives the data for that day
            d = $q.defer()
            data.then (response) ->
                d.resolve(response[date.toDateString()] || {})
            return d.promise
        getPossibleNames: ->
            # simulate a promise for now
            return {
                then: (f) ->
                    f(['Andrei', 'Andrew', 'Jonah', 'Paul'])
            }
        addPersonToDay: (args={}) ->
            {year, month, day, person} = args
            if year instanceof Date
                day = year.getDate()
                month = year.getMonth() + 1
                year = year.getFullYear()
            date = new Date(year, month - 1, day)
            
            # return a promise that resolves when the person
            # has been successfully added
            d = $q.defer()

            # for now, nothing will be permenantly changed
            data.then (response) ->
                response[date.toDateString()][person.name] =
                    name: person.name
                    times: [{start:10,end:11}]
                d.resolve()
            return d.promise

            
    return ret

app.factory('dataService', ['$http', '$q', dataService])

app.config(['$routeProvider',
    ($routeProvider) ->
        $routeProvider.when('/calendar', {templateUrl: 'calendar-template.html', controller: 'Calendar'})
            .when('/day', {templateUrl: 'dayview-template.html', controller: 'TimeViewController'})
            .when('/day/:year/:month/:day', {templateUrl: 'dayview-template.html', controller: 'TimeViewController'})
            .otherwise({redirectTo: '/calendar'})
    ])
