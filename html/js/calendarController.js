// Generated by CoffeeScript 1.9.0
var app;

app = angular.module('App', []);

app.controller('Calendar', [
  '$scope', function($scope) {
    var displayMonth, firstDay, locale, now, year;
    locale = 'en-us';
    now = new Date();
    year = now.getFullYear();
    $scope.month = now.toLocaleDateString(locale, {
      month: 'long'
    });
    displayMonth = new Date(year, month, 1);
    firstDay = displayMonth.getDay();
  }
]);
