###
# Helper Functions
###

# adds all the attributes of b to a
extend = (a,b) ->
    for k,v of b
        a[k] = v
    return a

###
# START OF THE APP
###
app = angular.module('App', ['ngRoute', 'calendarControllers', 'dayviewControllers'])

###
# MainController
###
mainController = ($scope, $routeParams, $location) ->
    $scope.showCalendar = ->
        $location.url('/calendar')
        return
    $scope.showDay = (date) ->
        day = date.getDate()
        month = date.getMonth() + 1
        year = date.getFullYear()
        $location.url("/day/#{year}/#{month}/#{day}")
        return

    $scope.abc = $routeParams.id || "default"

    # set up even listeners to see if we've clicked
    # and want to add a new time for someone
    return

app.controller('MainController', ['$scope', '$routeParams', '$location', mainController])

# fill a collection with JSON data.
# Data is expected to be an object indexed by dates.
populateDatabase = (collection, data) ->
    formattedData = []
    for k,v of data
        formattedData.push
            _id: k
            data: v
    collection.setData(formattedData)
    return


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

    # set up the forerunner DB. For now if the database is empty, 
    # we fill it with test data
    dbDeferred = $q.defer()
    db = new ForerunnerDB()
    collection = db.collection('sample')
    collection.load (err) ->
        dbDeferred.resolve()

    # populate sample data if its empty
    if collection.find().length == 0
        data.then (response) ->
            populateDatabase(collection, response)
            collection.save()

    ###
    # Returns the list of different people in the database
    # starting from startDate and working backwards MAX_DAYS
    # number of days
    ###
    MAX_DAYS = 60
    getProbableNames = (collection, startDate=new Date()) ->
        people = {}
        for i in [0...MAX_DAYS]
            date = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() - i)
            info = collection.findById(date.toDateString()) || {data:{}}
            for name of info.data
                people[name] = (people[name] || 0) + 1
        return people

    ret =
        get: (year, month, day, giveRecord=false) =>
            if year instanceof Date
                day = year.getDate()
                month = year.getMonth() + 1
                year = year.getFullYear()
            date = new Date(year, month - 1, day)

            # return a promise that gives the data for that day
            d = $q.defer()
            dbDeferred.promise.then ()->
                info = collection.findById(date.toDateString()) || {}
                if giveRecord
                    d.resolve(info)
                else
                    d.resolve(info.data)
            #data.then (response) ->
            #    d.resolve(response[date.toDateString()] || {})
            return d.promise
        setDayData: (args={}) ->
            {year, month, day, date, data} = args
            if year instanceof Date
                day = year.getDate()
                month = year.getMonth() + 1
                year = year.getFullYear()
            date = date || new Date(year, month - 1, day)

            # return a promise that resolves when the person
            # has been successfully added
            d = $q.defer()

            oldRecord = @get(date, null, null, true)
            oldRecord.then (response) ->
                response._id = response._id || date.toDateString()

                # somehow if we're called without data,
                # gracefully exit
                if not data?
                    return

                for k of response.data
                    # if we found an entry in our data that no longer exists,
                    # we need to clear the data to make sure it gets completely replaces
                    # since forerunnerdb by default will merge data
                    if !(data[k])
                        collection.update( {_id: response._id}, {$unset: {data: null}})
                        break

                collection.updateById(response._id, {data: data})
                d.resolve()
                collection.save()

            return d.promise

        getPossibleNames: () =>
            d = $q.defer()
            dbDeferred.promise.then ()->
                names = getProbableNames(collection)
                # make an array sorted by frequency the names appear
                ret = Object.keys(names)
                ret.sort( (a,b) -> return names[b] - names[a] )
                d.resolve(ret)
            return d.promise

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

            oldRecord = @get(date,null,null,true)
            oldRecord.then (response) ->
                response.data[person.name] =
                    name: person.name
                    times: [{start:10,end:11}]
                response._id = response._id || date.toDateString()

                collection.updateById(response._id, {data: response.data})
                d.resolve()
                collection.save()

            return d.promise

    return ret

app.factory('dataService', ['$http', '$q', dataService])

app.config(['$routeProvider',
    ($routeProvider) ->
        $routeProvider.when('/calendar', {templateUrl: 'calendar-template.html', controller: 'Calendar'})
            .when('/calendar/:year/:month', {templateUrl: 'calendar-template.html', controller: 'Calendar'})
            .when('/day', {templateUrl: 'dayview-template.html', controller: 'TimeViewController'})
            .when('/day/:year/:month/:day', {templateUrl: 'dayview-template.html', controller: 'TimeViewController'})
            .otherwise({redirectTo: '/calendar'})
    ])
