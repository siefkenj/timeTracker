###
# Helper Functions
###

randRange = (start=0, end=5) ->
    return start + Math.floor(Math.random()*(end-start+1))

randSample = (array, samples) ->
    arrayCpy = array.slice()
    ret = []
    for i in [0...samples]
        ret = ret.concat(arrayCpy.splice(randRange(0,arrayCpy.length-1), 1))
    return ret

# round to the nearest .5
roundToHalf = (t) ->
    return Math.round(2*t)/2

# creates a list with {thisday: <is ti the current day>, hour: <current hour>}
# with 0 = 12AM current day
createHourList = (start=-2, end=24+4) ->
    today = (t) -> if 0 <= i <= 24 then "today" else "not-today"
    hour = (t) -> "#{if t %% 12 == 0 then 12 else (t%%12)}#{if t %% 24 >=12 then 'pm' else 'am'}"
    return ({thisday: today(i), hour: hour(i)} for i in [start...end])

# take in a person object and return the total number of hours spent that day
getTotalHours = (p) ->
    total = 0
    for t in p.times
        total += t.end - t.start
    return total
# turn a time range into some classes
timeRangeToClassName = (t) ->
    formatNum = (x) ->
        if x %% 1 > 0
            return "#{Math.floor(x)}-5"
        else
            return "#{Math.floor(x)}-0"

    len = roundToHalf(t.end-t.start)
    start = roundToHalf(t.start)
    return "length-#{formatNum(len)} start-#{formatNum(start)}"
formatName = (person) ->
    return "#{person.name} (#{getTotalHours(person)})"


START_TIME = -2
END_TIME = 24 + 3


###
# START OF THE APP
###
app = angular.module('dayviewControllers', [])


###
# TimeViewController
###
timeviewController = ($scope, $routeParams, dataService) ->
    $scope.getTotalHours = getTotalHours
    $scope.timeRangeToClassName = timeRangeToClassName
    $scope.formatName = formatName

    $scope.hours = createHourList(START_TIME, END_TIME)
    console.log $scope.people
    console.log 'route params', $routeParams

    dataService.get($routeParams.year, $routeParams.month, $routeParams.day)
    .then (dayData) ->
        $scope.people = dayData
        console.log 'set people to', dayData

    $scope.booger = {start: -1}
    window.xxx = dataService
    window.yyy = $scope

    $scope.pp =
        name: 'Tomas'
        timespans: [{start: 4, end: 10}, {start: 2, end: 6}]

    # set up even listeners to see if we've clicked
    # and want to add a new time for someone

    return
adjustableRangeDirective = () ->
    return {
        link: (scope, elm, attrs) ->
            oldHourChange = null
            startY = null
            origTimeStart = scope.time.start
            origTimeEnd = scope.time.end
            interact($(elm).find('.top-handle')[0]).draggable({max: Infinity}).on('dragstart', (evt) ->
                startY = evt.pageY
                origTimeStart = scope.time.start
            ).on('dragmove', (evt) ->
                delta = startY - evt.pageY

                hourChange = roundToHalf(delta/23)  #XXX fix this constant!
                # if we drag enough to change the number of hours we span, update everything
                if hourChange != oldHourChange
                    oldHourChange = hourChange
                    scope.time.start = origTimeStart - hourChange
                    scope.$apply()
            )
            interact($(elm).find('.bottom-handle')[0]).draggable({max: Infinity}).on('dragstart', (evt) ->
                startY = evt.pageY
                origTimeEnd = scope.time.end
            ).on('dragmove', (evt) ->
                delta = startY - evt.pageY

                hourChange = roundToHalf(delta/23)  #XXX fix this constant!
                # if we drag enough to change the number of hours we span, update everything
                if hourChange != oldHourChange
                    oldHourChange = hourChange
                    scope.time.end = origTimeEnd - hourChange
                    scope.$apply()
            )
    }
timeColumnDirective = () ->
    return {
        link: (scope, elm, attrs) ->
            console.log 'linking!!', scope.person
    }
app.controller('TimeViewController', ['$scope', '$routeParams', 'dataService', timeviewController])
app.directive('adjustableRange', adjustableRangeDirective)
app.directive('timeColumn', adjustableRangeDirective)

adjustableHourWidget = ->
    directiveDefinitionObject =
        templateUrl: 'templates/adjustable-hour-widget-textbased.html'
        restrict: 'E'
        scope:
            startHour: '=startHour'
            endHour: '=endHour'
        link: (scope, element, attr) ->
            console.log 'meme', scope, element, attr
        controller: ($scope) ->
            console.log 'das controller', $scope
            $scope.increment = (which, direction) ->
                if which == 'start' and direction == '+'
                    $scope.startHour += .5
                if which == 'start' and direction == '-'
                    $scope.startHour -= .5
                if which == 'end' and direction == '+'
                    $scope.endHour += .5
                if which == 'end' and direction == '-'
                    $scope.endHour -= .5
    return directiveDefinitionObject

app.directive('adjustableHourWidget', adjustableHourWidget)

personDayInfoWidget = ->
    directiveDefinitionObject =
        templateUrl: 'templates/person-day-info-textbased.html'
        restrict: 'E'
        #transclude: true
        scope: {
            person: "=person"
        }
        #link: (scope, element, attr) ->
        #    console.log 'meme', scope, element, attr
        controller: ($scope) ->
            setTotalHours = ->
                total = 0
                for timespan in $scope.person.times
                    total += timespan.end - timespan.start
                $scope.totalHours = total

            $scope.$watch('person.times', setTotalHours, true)
            $scope.newTimespan = ->
                $scope.person.times.push({start: 10, end: 11})
            $scope.removeTimespan = (i) ->
                $scope.person.times.splice(i, 1)

    return directiveDefinitionObject

app.directive('personDayInfoWidget', personDayInfoWidget)
