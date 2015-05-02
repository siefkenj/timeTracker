// Generated by CoffeeScript 1.9.2

/*
 * Helper Functions
 */
var END_TIME, START_TIME, app, dataService, extend, mainController, populateDatabase;

START_TIME = -2;

END_TIME = 24 + 3;

extend = function(a, b) {
  var k, v;
  for (k in b) {
    v = b[k];
    a[k] = v;
  }
  return a;
};


/*
 * START OF THE APP
 */

app = angular.module('App', ['ngRoute', 'calendarControllers', 'dayviewControllers']);


/*
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
  $scope.abc = $routeParams.id || "default";
};

app.controller('MainController', ['$scope', '$routeParams', '$location', mainController]);

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
          info = collection.findById(date.toDateString()) || {};
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
        if (data == null) {
          return;
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

app.config([
  '$routeProvider', function($routeProvider) {
    return $routeProvider.when('/calendar', {
      templateUrl: 'calendar-template.html',
      controller: 'Calendar'
    }).when('/calendar/:year/:month', {
      templateUrl: 'calendar-template.html',
      controller: 'Calendar'
    }).when('/day', {
      templateUrl: 'dayview-template.html',
      controller: 'TimeViewController'
    }).when('/day/:year/:month/:day', {
      templateUrl: 'dayview-template.html',
      controller: 'TimeViewController'
    }).otherwise({
      redirectTo: '/calendar'
    });
  }
]);
