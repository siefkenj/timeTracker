// Generated by CoffeeScript 1.9.2

/*
 * Helper Functions
 */

(function() {
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
    var collection, data, db, dbDeferred, deferred, failure, ret, success;
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
          response.data = data;
          response._id = response._id || date.toDateString();
          collection.updateById(response._id, {
            data: response.data
          });
          d.resolve();
          return collection.save();
        });
        return d.promise;
      },
      getPossibleNames: (function(_this) {
        return function() {
          return {
            then: function(f) {
              return f(['Andrei', 'Andrew', 'Jonah', 'Paul']);
            }
          };
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
    window.aaa = ret;
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

}).call(this);
