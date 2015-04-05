// Generated by CoffeeScript 1.9.1

/*
 * Helper Functions
 */
var END_TIME, START_TIME, adjustableHourWidget, adjustableRangeDirective, app, createHourList, formatName, getTotalHours, newPersonDialog, personDayInfoWidget, randRange, randSample, roundToHalf, timeColumnDirective, timeRangeToClassName, timeviewController,
  modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

randRange = function(start, end) {
  if (start == null) {
    start = 0;
  }
  if (end == null) {
    end = 5;
  }
  return start + Math.floor(Math.random() * (end - start + 1));
};

randSample = function(array, samples) {
  var arrayCpy, i, j, ref, ret;
  arrayCpy = array.slice();
  ret = [];
  for (i = j = 0, ref = samples; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
    ret = ret.concat(arrayCpy.splice(randRange(0, arrayCpy.length - 1), 1));
  }
  return ret;
};

roundToHalf = function(t) {
  return Math.round(2 * t) / 2;
};

createHourList = function(start, end) {
  var hour, i, today;
  if (start == null) {
    start = -2;
  }
  if (end == null) {
    end = 24 + 4;
  }
  today = function(t) {
    if ((0 <= i && i <= 24)) {
      return "today";
    } else {
      return "not-today";
    }
  };
  hour = function(t) {
    return "" + (modulo(t, 12) === 0 ? 12 : modulo(t, 12)) + (modulo(t, 24) >= 12 ? 'pm' : 'am');
  };
  return (function() {
    var j, ref, ref1, results;
    results = [];
    for (i = j = ref = start, ref1 = end; ref <= ref1 ? j < ref1 : j > ref1; i = ref <= ref1 ? ++j : --j) {
      results.push({
        thisday: today(i),
        hour: hour(i)
      });
    }
    return results;
  })();
};

getTotalHours = function(p) {
  var j, len1, ref, t, total;
  total = 0;
  ref = p.times;
  for (j = 0, len1 = ref.length; j < len1; j++) {
    t = ref[j];
    total += t.end - t.start;
  }
  return total;
};

timeRangeToClassName = function(t) {
  var formatNum, len, start;
  formatNum = function(x) {
    if (modulo(x, 1) > 0) {
      return (Math.floor(x)) + "-5";
    } else {
      return (Math.floor(x)) + "-0";
    }
  };
  len = roundToHalf(t.end - t.start);
  start = roundToHalf(t.start);
  return "length-" + (formatNum(len)) + " start-" + (formatNum(start));
};

formatName = function(person) {
  return person.name + " (" + (getTotalHours(person)) + ")";
};

START_TIME = -2;

END_TIME = 24 + 3;


/*
 * START OF THE APP
 */

app = angular.module('dayviewControllers', []);


/*
 * TimeViewController
 */

timeviewController = function($scope, $routeParams, dataService) {
  var updatePeople;
  $scope.getTotalHours = getTotalHours;
  $scope.timeRangeToClassName = timeRangeToClassName;
  $scope.formatName = formatName;
  $scope.hours = createHourList(START_TIME, END_TIME);
  console.log($scope.people);
  console.log('route params', $routeParams);
  updatePeople = function() {
    return dataService.get($routeParams.year, $routeParams.month, $routeParams.day).then(function(dayData) {
      $scope.people = dayData;
      return console.log('set people to', dayData);
    });
  };
  updatePeople();
  $scope.possibleNames = [];
  dataService.getPossibleNames().then(function(names) {
    $scope.possibleNames = names;
    return console.log('got possible names', names);
  });
  $scope.showNewPersonDialog = false;
  $scope.newPerson = function() {
    return $scope.showNewPersonDialog = true;
  };
  $scope.addPerson = function(person) {
    var promise;
    promise = dataService.addPersonToDay({
      year: $routeParams.year,
      month: $routeParams.month,
      day: $routeParams.day,
      person: {
        name: person
      }
    });
    return promise.then(function() {
      updatePeople();
      return console.log("Adding", person);
    });
  };
  window.xxx = dataService;
  window.yyy = $scope;
  $scope.pp = {
    name: 'Tomas',
    timespans: [
      {
        start: 4,
        end: 10
      }, {
        start: 2,
        end: 6
      }
    ]
  };
};

adjustableRangeDirective = function() {
  return {
    link: function(scope, elm, attrs) {
      var oldHourChange, origTimeEnd, origTimeStart, startY;
      oldHourChange = null;
      startY = null;
      origTimeStart = scope.time.start;
      origTimeEnd = scope.time.end;
      interact($(elm).find('.top-handle')[0]).draggable({
        max: Infinity
      }).on('dragstart', function(evt) {
        startY = evt.pageY;
        return origTimeStart = scope.time.start;
      }).on('dragmove', function(evt) {
        var delta, hourChange;
        delta = startY - evt.pageY;
        hourChange = roundToHalf(delta / 23);
        if (hourChange !== oldHourChange) {
          oldHourChange = hourChange;
          scope.time.start = origTimeStart - hourChange;
          return scope.$apply();
        }
      });
      return interact($(elm).find('.bottom-handle')[0]).draggable({
        max: Infinity
      }).on('dragstart', function(evt) {
        startY = evt.pageY;
        return origTimeEnd = scope.time.end;
      }).on('dragmove', function(evt) {
        var delta, hourChange;
        delta = startY - evt.pageY;
        hourChange = roundToHalf(delta / 23);
        if (hourChange !== oldHourChange) {
          oldHourChange = hourChange;
          scope.time.end = origTimeEnd - hourChange;
          return scope.$apply();
        }
      });
    }
  };
};

timeColumnDirective = function() {
  return {
    link: function(scope, elm, attrs) {
      return console.log('linking!!', scope.person);
    }
  };
};

app.controller('TimeViewController', ['$scope', '$routeParams', 'dataService', timeviewController]);

app.directive('adjustableRange', adjustableRangeDirective);

app.directive('timeColumn', adjustableRangeDirective);

adjustableHourWidget = function() {
  return {
    templateUrl: 'templates/adjustable-hour-widget-textbased.html',
    restrict: 'E',
    scope: {
      startHour: '=startHour',
      endHour: '=endHour'
    },
    link: function(scope, element, attr) {
      return console.log('meme', scope, element, attr);
    },
    controller: function($scope) {
      console.log('das controller', $scope);
      return $scope.increment = function(which, direction) {
        if (which === 'start' && direction === '+') {
          $scope.startHour += .5;
        }
        if (which === 'start' && direction === '-') {
          $scope.startHour -= .5;
        }
        if (which === 'end' && direction === '+') {
          $scope.endHour += .5;
        }
        if (which === 'end' && direction === '-') {
          return $scope.endHour -= .5;
        }
      };
    }
  };
};

app.directive('adjustableHourWidget', adjustableHourWidget);

personDayInfoWidget = function() {
  return {
    templateUrl: 'templates/person-day-info-textbased.html',
    restrict: 'E',
    scope: {
      person: "=person"
    },
    controller: function($scope) {
      var setTotalHours;
      setTotalHours = function() {
        var j, len1, ref, timespan, total;
        total = 0;
        ref = $scope.person.times;
        for (j = 0, len1 = ref.length; j < len1; j++) {
          timespan = ref[j];
          total += timespan.end - timespan.start;
        }
        return $scope.totalHours = total;
      };
      $scope.$watch('person.times', setTotalHours, true);
      $scope.newTimespan = function() {
        return $scope.person.times.push({
          start: 10,
          end: 11
        });
      };
      return $scope.removeTimespan = function(i) {
        return $scope.person.times.splice(i, 1);
      };
    }
  };
};

app.directive('personDayInfoWidget', personDayInfoWidget);

newPersonDialog = function() {
  var directiveDefinitionObject;
  directiveDefinitionObject = {
    templateUrl: 'templates/new-person-textbased.html',
    restrict: 'E',
    scope: {
      possibleNames: "=possibleNames",
      addPerson: "=addPerson",
      showDialog: "=ngShow"
    },
    controller: function($scope) {
      $scope.addPersonClick = function(newName) {
        console.log("you want to add " + newName);
        if (typeof $scope.addPerson === "function") {
          $scope.addPerson(newName);
        }
        return $scope.showDialog = false;
      };
      return $scope.cancel = function() {
        console.log("canceling...");
        return $scope.showDialog = false;
      };
    }
  };
  return directiveDefinitionObject;
};

app.directive('newPersonDialog', newPersonDialog);
