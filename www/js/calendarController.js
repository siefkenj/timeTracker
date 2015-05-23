// Generated by CoffeeScript 1.9.2

/*
 * Here we define all controllers relavent to the calendar view
 */
var LOCALE, app, calendarController, calendarDayWidget, setupMonth;

app = angular.module('calendarControllers', []);


/*
 * CalendarController
 */

LOCALE = "en-us";

calendarController = function($scope, $http, $routeParams, dataService) {
  var now;
  now = new Date();
  $scope.monthNum = ($routeParams.month - 1) | 0 || now.getMonth();
  $scope.yearNum = $routeParams.year | 0 || now.getFullYear();
  window.ss = $scope;
  $scope.monthToString = function(m) {
    return (new Date($scope.yearNum, m)).toLocaleDateString(LOCALE, {
      month: 'long'
    });
  };
  $scope.monthList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  $scope.incMonth = function(inc) {
    return $scope.monthNum += inc;
  };
  $scope.monthName = function() {
    var date, locale, nav;
    nav = window.navigator;
    locale = nav.language || nav.userLanguage;
    date = new Date($scope.yearNum, $scope.monthNum, 1);
    return date.toLocaleDateString(locale, {
      month: 'long'
    });
  };
  $scope.$watch('monthNum', function() {
    var newDate;
    newDate = new Date($scope.yearNum, $scope.monthNum, 1);
    return $scope.displayDays = setupMonth(newDate, dataService);
  });
};

setupMonth = function(displayMonth, dataService) {
  var day, displayDays, firstDay, getDate, i, index, lastMonth, len, month, nextMonth, numDays, remainingDays, result, thisMonth, week, x, year;
  getDate = function(date) {
    var ret;
    ret = {
      jsDate: date,
      date: date.getDate(),
      data: null
    };
    dataService.get(ret.jsDate).then(function(dayData) {
      return ret.data = dayData;
    });
    return ret;
  };
  year = displayMonth.getFullYear();
  month = displayMonth.getMonth();
  firstDay = displayMonth.getDay();
  lastMonth = ((function() {
    var i, ref, results;
    results = [];
    for (x = i = 0, ref = firstDay; 0 <= ref ? i < ref : i > ref; x = 0 <= ref ? ++i : --i) {
      results.push(getDate(new Date(year, month, -x)));
    }
    return results;
  })()).reverse();
  numDays = (new Date(year, month + 1, 0)).getDate();
  thisMonth = (function() {
    var i, ref, results;
    results = [];
    for (x = i = 1, ref = numDays; 1 <= ref ? i < ref : i > ref; x = 1 <= ref ? ++i : --i) {
      results.push(getDate(new Date(year, month, x)));
    }
    return results;
  })();
  remainingDays = 7 - (new Date(year, month + 1, 0)).getDay();
  nextMonth = (function() {
    var i, ref, results;
    results = [];
    for (x = i = 0, ref = remainingDays; 0 <= ref ? i < ref : i > ref; x = 0 <= ref ? ++i : --i) {
      results.push(getDate(new Date(year, month + 1, x + 1)));
    }
    return results;
  })();
  displayDays = lastMonth.concat(thisMonth.concat(nextMonth));
  result = [];
  week = [];
  for (index = i = 0, len = displayDays.length; i < len; index = ++i) {
    day = displayDays[index];
    week.push(day);
    if (!((index + 1) % 7)) {
      result.push(week);
      week = [];
    }
  }
  return result;
};

app.controller('CalendarController', ['$scope', '$http', '$routeParams', 'dataService', calendarController]);

calendarDayWidget = function() {
  return {
    templateUrl: 'templates/calendar_day_widget.html',
    restrict: 'E',
    scope: {
      day: "=day"
    }
  };
};

app.directive('calendarDayWidget', calendarDayWidget);
