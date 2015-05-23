// Generated by CoffeeScript 1.9.2

/*
 * START OF THE APP
 */
var app, dataService, mainController, populateDatabase;

app = angular.module('App', ['ngRoute', 'calendarControllers', 'dayControllers']);

app.config([
  '$routeProvider', function($routeProvider) {
    return $routeProvider.when('/calendar', {
      templateUrl: 'templates/calendar.tmpl.html',
      controller: 'CalendarController'
    }).when('/calendar/:year/:month', {
      templateUrl: 'templates/calendar.tmpl.html',
      controller: 'CalendarController'
    }).when('/day', {
      templateUrl: 'templates/day.tmpl.html',
      controller: 'DayController'
    }).when('/day/:year/:month/:day', {
      templateUrl: 'templates/day.tmpl.html',
      controller: 'DayController'
    }).otherwise({
      redirectTo: '/calendar'
    });
  }
]);


/*
#
 * MainController
 */

mainController = function($scope, $routeParams, $location) {
  $scope.showCalendar = function() {
    $location.url('/calendar');
  };
  $scope.showDay = function(date) {
    var day, month, year;
    day = date.getDate();
    month = date.getMonth() + 1;
    year = date.getFullYear();
    $location.url("/day/" + year + "/" + month + "/" + day);
  };
};

app.controller('MainController', ['$scope', '$routeParams', '$location', mainController]);


/*
 * dataService
#
 * dataService is the angular interface to the database backend
 */

populateDatabase = function(collection, data) {
  var formattedData, k, v;
  formattedData = [];
  for (k in data) {
    v = data[k];
    formattedData.push({
      _id: k,
      data: v
    });
  }
  collection.setData(formattedData);
};

dataService = function($http, $q) {
  var MAX_DAYS, collection, data, db, dbDeferred, deferred, failure, getProbableNames, ret, success;
  deferred = $q.defer();
  success = function(response) {
    return deferred.resolve(response);
  };
  failure = function(response) {
    return deferred.reject(response);
  };
  $http.get("js/test-hangout-data.json").success(success).error(failure);
  data = deferred.promise;
  dbDeferred = $q.defer();
  db = new ForerunnerDB();
  collection = db.collection('sample');
  collection.load(function(err) {
    return dbDeferred.resolve();
  });
  if (collection.find().length === 0) {
    data.then(function(response) {
      populateDatabase(collection, response);
      return collection.save();
    });
  }

  /*
   * Returns the list of different people in the database
   * starting from startDate and working backwards MAX_DAYS
   * number of days
   */
  MAX_DAYS = 60;
  getProbableNames = function(collection, startDate) {
    var date, i, info, j, name, people, ref;
    if (startDate == null) {
      startDate = new Date();
    }
    people = {};
    for (i = j = 0, ref = MAX_DAYS; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      date = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() - i);
      info = collection.findById(date.toDateString()) || {
        data: {}
      };
      for (name in info.data) {
        people[name] = (people[name] || 0) + 1;
      }
    }
    return people;
  };
  ret = {
    collection: collection,
    get: (function(_this) {
      return function(year, month, day, giveRecord) {
        var d, date;
        if (giveRecord == null) {
          giveRecord = false;
        }
        if (year instanceof Date) {
          day = year.getDate();
          month = year.getMonth() + 1;
          year = year.getFullYear();
        }
        date = new Date(year, month - 1, day);
        d = $q.defer();
        dbDeferred.promise.then(function() {
          var info;
          info = collection.findById(date.toDateString()) || {
            data: {},
            emptyData: true
          };
          if (giveRecord) {
            return d.resolve(info);
          } else {
            return d.resolve(info.data);
          }
        });
        return d.promise;
      };
    })(this),
    setDayData: function(args) {
      var d, date, day, month, oldRecord, year;
      if (args == null) {
        args = {};
      }
      year = args.year, month = args.month, day = args.day, date = args.date, data = args.data;
      if (data == null) {
        return;
      }
      if (year instanceof Date) {
        day = year.getDate();
        month = year.getMonth() + 1;
        year = year.getFullYear();
      }
      date = date || new Date(year, month - 1, day);
      d = $q.defer();
      oldRecord = this.get(date, null, null, true);
      oldRecord.then(function(response) {
        var k;
        response._id = response._id || date.toDateString();
        if (response.emptyData) {
          delete response.emptyData;
          collection.insert(response);
        }
        for (k in response.data) {
          if (!data[k]) {
            collection.update({
              _id: response._id
            }, {
              $unset: {
                data: null
              }
            });
            break;
          }
        }
        collection.updateById(response._id, {
          data: data
        });
        d.resolve();
        return collection.save();
      });
      return d.promise;
    },
    getPossibleNames: (function(_this) {
      return function() {
        var d;
        d = $q.defer();
        dbDeferred.promise.then(function() {
          var names;
          names = getProbableNames(collection);
          ret = Object.keys(names);
          ret.sort(function(a, b) {
            return names[b] - names[a];
          });
          return d.resolve(ret);
        });
        return d.promise;
      };
    })(this),
    addPersonToDay: function(args) {
      var d, date, day, month, oldRecord, person, year;
      if (args == null) {
        args = {};
      }
      year = args.year, month = args.month, day = args.day, person = args.person;
      if (year instanceof Date) {
        day = year.getDate();
        month = year.getMonth() + 1;
        year = year.getFullYear();
      }
      date = new Date(year, month - 1, day);
      d = $q.defer();
      oldRecord = this.get(date, null, null, true);
      oldRecord.then(function(response) {
        console.log('xx', response);
        response.data[person.name] = {
          name: person.name,
          times: [
            {
              start: 10,
              end: 11
            }
          ]
        };
        response._id = response._id || date.toDateString();
        collection.updateById(response._id, {
          data: response.data
        });
        d.resolve();
        return collection.save();
      });
      return d.promise;
    }
  };
  return ret;
};

app.factory('dataService', ['$http', '$q', dataService]);
