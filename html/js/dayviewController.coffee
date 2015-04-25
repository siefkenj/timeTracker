###
# Helper Functions
###

# round to the nearest .5
roundToHalf = (t) ->
    return Math.round(2*t)/2

# creates a list with {thisday: <is ti the current day>, hour: <current hour>}
# with 0 = 12AM current day
createHourList = (start=-2, end=24+4) ->
    today = (t) -> if 0 <= i <= 24 then "today" else "not-today"
    hour = (t) -> "#{if t %% 12 == 0 then 12 else (t%%12)}#{if t %% 24 >=12 then 'pm' else 'am'}"
    return ({thisday: today(i), hour: hour(i), time: i} for i in [start...end])

# take in a person object and return the total number of hours spent that day
getTotalHours = (p) ->
    total = 0
    for t in p.times
        total += t.end - t.start
    return total

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

    $scope.hours = createHourList(START_TIME, END_TIME)

    updatePeople = ->
        dataService.get($routeParams.year, $routeParams.month, $routeParams.day)
        .then (dayData) ->
            $scope.people = dayData
    updatePeople()

    $scope.possibleNames = []
    dataService.getPossibleNames().then (names) ->
        $scope.possibleNames = names

    $scope.showNewPersonDialog = false
    $scope.newPerson = ->
        $scope.showNewPersonDialog = true
    $scope.addPerson = (person) ->
        promise = dataService.addPersonToDay
            year: $routeParams.year
            month: $routeParams.month
            day: $routeParams.day
            person: {name: person}
        promise.then ->
            updatePeople()

    dataChanged = ->
        dataService.setDayData
            year: $routeParams.year
            month: $routeParams.month
            day: $routeParams.day
            data: $scope.people

    $scope.$watch('people', dataChanged, true)

    return
app.controller('TimeViewController', ['$scope', '$routeParams', 'dataService', timeviewController])

adjustableHourWidget = ->
    templateUrl: 'templates/adjustable-hour-widget.html'
    restrict: 'E'
    scope:
        startHour: '=startHour'
        endHour: '=endHour'
        offsets: '=offsets'
    link: (scope, elm, attr) ->
        oldHourChange = null
        startY = null
        origTimeStart = scope.startHour
        origTimeEnd = scope.endHour

        hourHeigh = scope.$parent.offsets?.height || 25
        
        bounds = scope.$parent.computeValidTimeRange((origTimeStart+origTimeEnd)/2, {start: origTimeStart, end: origTimeEnd})
        
        top = interact($(elm).find('.top-time')[0])
        top.draggable({max: Infinity})
        top.on 'dragstart', (evt) ->
            startY = evt.pageY
            origTimeStart = scope.startHour
            origTimeEnd = scope.endHour
            bounds = scope.$parent.computeValidTimeRange((origTimeStart+origTimeEnd)/2, {start: origTimeStart, end: origTimeEnd})
        top.on 'dragmove', (evt) ->
            delta = startY - evt.pageY

            hourChange = roundToHalf(delta/hourHeigh)
            # if we drag enough to change the number of hours we span, update everything
            if hourChange != oldHourChange
                oldHourChange = hourChange
                startHour = origTimeStart - hourChange
                # make sure we stay in bounds
                startHour = Math.max(startHour, bounds.start)
                # make sure we don't cross over ourself
                startHour = Math.min(startHour, origTimeEnd - .5)
                scope.startHour = startHour
                scope.$apply()
        
        bottom = interact($(elm).find('.bottom-time')[0])
        bottom.draggable({max: Infinity})
        bottom.on 'dragstart', (evt) ->
            startY = evt.pageY
            origTimeEnd = scope.endHour
            origTimeStart = scope.startHour
            bounds = scope.$parent.computeValidTimeRange((origTimeStart+origTimeEnd)/2, {start: origTimeStart, end: origTimeEnd})
        bottom.on 'dragmove', (evt) ->
            delta = startY - evt.pageY

            hourChange = roundToHalf(delta/hourHeigh)
            # if we drag enough to change the number of hours we span, update everything
            if hourChange != oldHourChange
                oldHourChange = hourChange
                endHour = origTimeEnd - hourChange
                # make sure we stay in bounds
                endHour = Math.min(endHour, bounds.end)
                # make sure we don't cross over ourself
                endHour = Math.max(endHour, origTimeStart + .5)
                scope.endHour = endHour
                scope.$apply()
        scope.container = elm.find('.hourspan-container')
        
    controller: ($scope) ->
        # turn hour into a hour-{0,5} rounding to the nearest half hour
        $scope.cssTime = (hour) ->
            half = if hour % 1 >= .5 then 5 else 0
            hour = Math.floor(hour)
            return "#{hour}-#{half}"
        $scope.formatTime = (hour) ->
            minute = Math.floor((hour % 1)*60)
            minute = "00#{minute}".slice(-2)
            ampm = if hour < 0 or hour >= 12 then "pm" else "am"
            hour = Math.floor(hour) %% 12
            if hour == 0
                hour = 12
            return "#{hour}:#{minute}#{ampm}"

        $scope.$watchGroup ['startHour','endHour'], ->
            offsets = $scope.$parent.computeHourOffsets()
            top = offsets[$scope.startHour]
            bottom = offsets.totalHeight - offsets[$scope.endHour]
            height = offsets[$scope.endHour] - top
            $scope.container.css({top: top, bottom: bottom, height: height})
            if height < 100
                $scope.container.addClass('compact-vert')
            else
                $scope.container.removeClass('compact-vert')

        $scope.deleteClicked = ->
            # remove a timeRange matching ourselves when the delete is clicked
            $scope.$parent.removeTimeRange({start: $scope.startHour, end: $scope.endHour})


app.directive('adjustableHourWidget', adjustableHourWidget)

personDayInfoWidget = ->
    templateUrl: 'templates/person-day-info.html'
    restrict: 'E'
    scope:
        person: "=person"
        hours: "=hours"
    link: (scope, element, attr) ->
        scope.container = element

    controller: ($scope) ->
        setTotalHours = ->
            total = 0
            for timespan in $scope.person.times
                total += timespan.end - timespan.start
            $scope.totalHours = total

        $scope.offsets = {}
        # loop through and find the offsets
        # for each div marking an hour.
        $scope.computeHourOffsets = ->
            tops = (x.offsetTop for x in $scope.container.find('.hours'))
            height = $scope.container.find('.hours')[0]?.offsetHeight || 0

            startTime = -2
            endTime = startTime + tops.length

            $scope.offsets = {}
            for i in [startTime..endTime]
                $scope.offsets[i] = tops[i - startTime]
                $scope.offsets[i + .5] = tops[i - startTime] + height/2
            $scope.offsets.height = height
            $scope.offsets.totalHeight = tops[tops.length - 1] + height
            #$scope.offsets.totalHeight = $scope.container.height()
            return $scope.offsets

        $scope.$watch('person.times', setTotalHours, true)
        $scope.newTimespan = ->
            $scope.person.times.push({start: 10, end: 11})
        $scope.removeTimespan = (i) ->
            $scope.person.times.splice(i, 1)

        # compute the largest time interval
        # a timespan can occupy centered at initTime
        # if ignoreRange is set, then that time interval
        # is treated as if it isn't there
        $scope.computeValidTimeRange = (initTime, ignoreRange={}) ->
            useableIntervals = (i for i in $scope.person.times when (i.start != ignoreRange.start and i.end != ignoreRange.end))
            
            end = Math.min.apply(null, (i.start for i in useableIntervals when (i.start >= initTime)))
            end = Math.min(26, end)     # fix these hardcoded values
            start = Math.max.apply(null, (i.end for i in useableIntervals when (i.end <= initTime)))
            start = Math.max(-3, start)

            return {start: start, end: end}
        $scope.removeTimeRange = (timeRange) ->
            for r,i in $scope.person.times
                if r.start == timeRange.start and r.end == timeRange.end
                    removeIndex = i
            if removeIndex?
                $scope.person.times.splice(removeIndex, 1)
            return
        $scope.newTime = (hour, defaultDuration=2) ->
            range = $scope.computeValidTimeRange(hour)
            # create a new range that defaults to defaultDuration hours 
            # but is garunteed to remain in the bounds of range
            newRange =
                start: hour
                end: hour + defaultDuration
            newRange.end = Math.min(newRange.end, range.end)
            newRange.start = newRange.end - defaultDuration
            newRange.start = Math.max(newRange.start, range.start)
            
            $scope.person.times.push(newRange)

        window.sss = $scope

app.directive('personDayInfoWidget', personDayInfoWidget)

newPersonDialog = ->
    directiveDefinitionObject =
        templateUrl: 'templates/new-person-textbased.html'
        restrict: 'E'
        scope: {
            possibleNames: "=possibleNames"
            addPerson: "=addPerson"
            showDialog: "=ngShow"
        }
        #link: (scope, element, attr) ->
        #    console.log 'meme', scope, element, attr
        controller: ($scope) ->
            $scope.addPersonClick = (newName) ->
                console.log("you want to add #{newName}")
                $scope.addPerson?(newName)
                $scope.showDialog = false
            $scope.cancel = ->
                console.log("canceling...")
                $scope.showDialog = false

    return directiveDefinitionObject

app.directive('newPersonDialog', newPersonDialog)





###
# Textbased widgets
###

adjustableHourWidgetTextbased = ->
    templateUrl: 'templates/adjustable-hour-widget-textbased.html'
    restrict: 'E'
    scope:
        startHour: '=startHour'
        endHour: '=endHour'
    #link: (scope, element, attr) ->
    #    console.log 'meme', scope, element, attr
    controller: ($scope) ->
        $scope.increment = (which, direction) ->
            if which == 'start' and direction == '+'
                $scope.startHour += .5
            if which == 'start' and direction == '-'
                $scope.startHour -= .5
            if which == 'end' and direction == '+'
                $scope.endHour += .5
            if which == 'end' and direction == '-'
                $scope.endHour -= .5
app.directive('adjustableHourWidgetTextbased', adjustableHourWidgetTextbased)

personDayInfoWidgetTextbased = ->
    templateUrl: 'templates/person-day-info-textbased.html'
    restrict: 'E'
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
app.directive('personDayInfoWidgetTextbased', personDayInfoWidgetTextbased)

