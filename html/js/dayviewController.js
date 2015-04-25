// Generated by CoffeeScript 1.9.1

/*
 * Helper Functions
 */
var END_TIME, START_TIME, adjustableHourWidget, adjustableHourWidgetTextbased, app, createHourList, getTotalHours, newPersonDialog, personDayInfoWidget, personDayInfoWidgetTextbased, roundToHalf, timeviewController,
  modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

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
        hour: hour(i),
        time: i
      });
    }
    return results;
  })();
};

getTotalHours = function(p) {
  var j, len, ref, t, total;
  total = 0;
  ref = p.times;
  for (j = 0, len = ref.length; j < len; j++) {
    t = ref[j];
    total += t.end - t.start;
  }
  return total;
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
  var dataChanged, updatePeople;
  $scope.getTotalHours = getTotalHours;
  $scope.hours = createHourList(START_TIME, END_TIME);
  updatePeople = function() {
    return dataService.get($routeParams.year, $routeParams.month, $routeParams.day).then(function(dayData) {
      return $scope.people = dayData;
    });
  };
  updatePeople();
  $scope.possibleNames = [];
  dataService.getPossibleNames().then(function(names) {
    return $scope.possibleNames = names;
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
      return updatePeople();
    });
  };
  dataChanged = function() {
    return dataService.setDayData({
      year: $routeParams.year,
      month: $routeParams.month,
      day: $routeParams.day,
      data: $scope.people
    });
  };
  $scope.$watch('people', dataChanged, true);
};

app.controller('TimeViewController', ['$scope', '$routeParams', 'dataService', timeviewController]);

adjustableHourWidget = function() {
  return {
    templateUrl: 'templates/adjustable-hour-widget.html',
    restrict: 'E',
    scope: {
      startHour: '=startHour',
      endHour: '=endHour',
      offsets: '=offsets'
    },
    link: function(scope, elm, attr) {
      var bottom, bounds, hourHeigh, oldHourChange, origTimeEnd, origTimeStart, ref, startY, top;
      oldHourChange = null;
      startY = null;
      origTimeStart = scope.startHour;
      origTimeEnd = scope.endHour;
      hourHeigh = ((ref = scope.$parent.offsets) != null ? ref.height : void 0) || 25;
      bounds = scope.$parent.computeValidTimeRange((origTimeStart + origTimeEnd) / 2, {
        start: origTimeStart,
        end: origTimeEnd
      });
      top = interact($(elm).find('.top-time')[0]);
      top.draggable({
        max: Infinity
      });
      top.on('dragstart', function(evt) {
        startY = evt.pageY;
        origTimeStart = scope.startHour;
        origTimeEnd = scope.endHour;
        return bounds = scope.$parent.computeValidTimeRange((origTimeStart + origTimeEnd) / 2, {
          start: origTimeStart,
          end: origTimeEnd
        });
      });
      top.on('dragmove', function(evt) {
        var delta, hourChange, startHour;
        delta = startY - evt.pageY;
        hourChange = roundToHalf(delta / hourHeigh);
        if (hourChange !== oldHourChange) {
          oldHourChange = hourChange;
          startHour = origTimeStart - hourChange;
          startHour = Math.max(startHour, bounds.start);
          startHour = Math.min(startHour, origTimeEnd - .5);
          scope.startHour = startHour;
          return scope.$apply();
        }
      });
      bottom = interact($(elm).find('.bottom-time')[0]);
      bottom.draggable({
        max: Infinity
      });
      bottom.on('dragstart', function(evt) {
        startY = evt.pageY;
        origTimeEnd = scope.endHour;
        origTimeStart = scope.startHour;
        return bounds = scope.$parent.computeValidTimeRange((origTimeStart + origTimeEnd) / 2, {
          start: origTimeStart,
          end: origTimeEnd
        });
      });
      bottom.on('dragmove', function(evt) {
        var delta, endHour, hourChange;
        delta = startY - evt.pageY;
        hourChange = roundToHalf(delta / hourHeigh);
        if (hourChange !== oldHourChange) {
          oldHourChange = hourChange;
          endHour = origTimeEnd - hourChange;
          endHour = Math.min(endHour, bounds.end);
          endHour = Math.max(endHour, origTimeStart + .5);
          scope.endHour = endHour;
          return scope.$apply();
        }
      });
      return scope.container = elm.find('.hourspan-container');
    },
    controller: function($scope) {
      $scope.cssTime = function(hour) {
        var half;
        half = hour % 1 >= .5 ? 5 : 0;
        hour = Math.floor(hour);
        return hour + "-" + half;
      };
      $scope.formatTime = function(hour) {
        var ampm, minute;
        minute = Math.floor((hour % 1) * 60);
        minute = ("00" + minute).slice(-2);
        ampm = hour < 0 || hour >= 12 ? "pm" : "am";
        hour = modulo(Math.floor(hour), 12);
        if (hour === 0) {
          hour = 12;
        }
        return hour + ":" + minute + ampm;
      };
      $scope.$watchGroup(['startHour', 'endHour'], function() {
        var bottom, height, offsets, top;
        offsets = $scope.$parent.computeHourOffsets();
        top = offsets[$scope.startHour];
        bottom = offsets.totalHeight - offsets[$scope.endHour];
        height = offsets[$scope.endHour] - top;
        $scope.container.css({
          top: top,
          bottom: bottom,
          height: height
        });
        if (height < 100) {
          return $scope.container.addClass('compact-vert');
        } else {
          return $scope.container.removeClass('compact-vert');
        }
      });
      return $scope.deleteClicked = function() {
        return $scope.$parent.removeTimeRange({
          start: $scope.startHour,
          end: $scope.endHour
        });
      };
    }
  };
};

app.directive('adjustableHourWidget', adjustableHourWidget);

personDayInfoWidget = function() {
  return {
    templateUrl: 'templates/person-day-info.html',
    restrict: 'E',
    scope: {
      person: "=person",
      hours: "=hours"
    },
    link: function(scope, element, attr) {
      return scope.container = element;
    },
    controller: function($scope) {
      var setTotalHours;
      setTotalHours = function() {
        var j, len, ref, timespan, total;
        total = 0;
        ref = $scope.person.times;
        for (j = 0, len = ref.length; j < len; j++) {
          timespan = ref[j];
          total += timespan.end - timespan.start;
        }
        return $scope.totalHours = total;
      };
      $scope.offsets = {};
      $scope.computeHourOffsets = function() {
        var endTime, height, i, j, ref, ref1, ref2, startTime, tops, x;
        tops = (function() {
          var j, len, ref, results;
          ref = $scope.container.find('.hours');
          results = [];
          for (j = 0, len = ref.length; j < len; j++) {
            x = ref[j];
            results.push(x.offsetTop);
          }
          return results;
        })();
        height = ((ref = $scope.container.find('.hours')[0]) != null ? ref.offsetHeight : void 0) || 0;
        startTime = -2;
        endTime = startTime + tops.length;
        $scope.offsets = {};
        for (i = j = ref1 = startTime, ref2 = endTime; ref1 <= ref2 ? j <= ref2 : j >= ref2; i = ref1 <= ref2 ? ++j : --j) {
          $scope.offsets[i] = tops[i - startTime];
          $scope.offsets[i + .5] = tops[i - startTime] + height / 2;
        }
        $scope.offsets.height = height;
        $scope.offsets.totalHeight = tops[tops.length - 1] + height;
        return $scope.offsets;
      };
      $scope.$watch('person.times', setTotalHours, true);
      $scope.newTimespan = function() {
        return $scope.person.times.push({
          start: 10,
          end: 11
        });
      };
      $scope.removeTimespan = function(i) {
        return $scope.person.times.splice(i, 1);
      };
      $scope.computeValidTimeRange = function(initTime, ignoreRange) {
        var end, i, start, useableIntervals;
        if (ignoreRange == null) {
          ignoreRange = {};
        }
        useableIntervals = (function() {
          var j, len, ref, results;
          ref = $scope.person.times;
          results = [];
          for (j = 0, len = ref.length; j < len; j++) {
            i = ref[j];
            if (i.start !== ignoreRange.start && i.end !== ignoreRange.end) {
              results.push(i);
            }
          }
          return results;
        })();
        end = Math.min.apply(null, (function() {
          var j, len, results;
          results = [];
          for (j = 0, len = useableIntervals.length; j < len; j++) {
            i = useableIntervals[j];
            if (i.start >= initTime) {
              results.push(i.start);
            }
          }
          return results;
        })());
        end = Math.min(26, end);
        start = Math.max.apply(null, (function() {
          var j, len, results;
          results = [];
          for (j = 0, len = useableIntervals.length; j < len; j++) {
            i = useableIntervals[j];
            if (i.end <= initTime) {
              results.push(i.end);
            }
          }
          return results;
        })());
        start = Math.max(-3, start);
        return {
          start: start,
          end: end
        };
      };
      $scope.removeTimeRange = function(timeRange) {
        var i, j, len, r, ref, removeIndex;
        ref = $scope.person.times;
        for (i = j = 0, len = ref.length; j < len; i = ++j) {
          r = ref[i];
          if (r.start === timeRange.start && r.end === timeRange.end) {
            removeIndex = i;
          }
        }
        if (removeIndex != null) {
          $scope.person.times.splice(removeIndex, 1);
        }
      };
      $scope.newTime = function(hour, defaultDuration) {
        var newRange, range;
        if (defaultDuration == null) {
          defaultDuration = 2;
        }
        range = $scope.computeValidTimeRange(hour);
        newRange = {
          start: hour,
          end: hour + defaultDuration
        };
        newRange.end = Math.min(newRange.end, range.end);
        newRange.start = newRange.end - defaultDuration;
        newRange.start = Math.max(newRange.start, range.start);
        return $scope.person.times.push(newRange);
      };
      return window.sss = $scope;
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


/*
 * Textbased widgets
 */

adjustableHourWidgetTextbased = function() {
  return {
    templateUrl: 'templates/adjustable-hour-widget-textbased.html',
    restrict: 'E',
    scope: {
      startHour: '=startHour',
      endHour: '=endHour'
    },
    controller: function($scope) {
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

app.directive('adjustableHourWidgetTextbased', adjustableHourWidgetTextbased);

personDayInfoWidgetTextbased = function() {
  return {
    templateUrl: 'templates/person-day-info-textbased.html',
    restrict: 'E',
    scope: {
      person: "=person"
    },
    controller: function($scope) {
      var setTotalHours;
      setTotalHours = function() {
        var j, len, ref, timespan, total;
        total = 0;
        ref = $scope.person.times;
        for (j = 0, len = ref.length; j < len; j++) {
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

app.directive('personDayInfoWidgetTextbased', personDayInfoWidgetTextbased);
