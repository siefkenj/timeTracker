
###
# START OF THE APP
###
app = angular.module('dayControllers', [])


###
# DayController
###
START_TIME = -2
END_TIME = 24+2
dayController = ($scope, $routeParams, dataService) ->
    window.ds = dataService
    #$scope.getTotalHours = getTotalHours
    $scope.year = $routeParams.year
    $scope.month = $routeParams.month
    $scope.day = $routeParams.day

    $scope.hours = createHourList(START_TIME, END_TIME)

    updatePeople = ->
        dataService.get($routeParams.year, $routeParams.month, $routeParams.day)
        .then (dayData) ->
            $scope.people = dayData
    #updatePeople()
    $scope.people = [
        { name: 'Andrew', times: [{start:10, end:12}, {start:4, end:8}] },
        { name: 'Seth', times: [{start:4, end:8}] },
        { name: 'Paul', times: [{start:14, end:15.5}] },
    ]

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
app.controller('DayController', ['$scope', '$routeParams', 'dataService', dayController])


###
# Widgets
###

dayTableWidget = ->
    templateUrl: 'day-table.tmpl.html'
    restrict: 'E'
    scope:
        people: '='
        hours: '='
    link: (scope, element, attr) ->
        scope.container = element
    controller: ($scope) ->
        # these are the position offsets
        # for each column
        $scope.offsets = {}
        $scope.hourHeight = 20
        $scope.computeOffsets = ->
            # first compute the top of every row
            tops = {}
            for hour in [START_TIME..END_TIME]
                row = $scope.container.find("[x-hour=\"#{hour}\"]")[0]
                if row
                    tops[hour] = row.offsetTop

            for person in $scope.people
                col = $scope.container.find("[x-name=\"#{person.name}\"]")[0]
                if not col?
                    return
                $scope.offsets[person.name] =
                    left: col.offsetLeft
                    width: col.offsetWidth
                    tops: tops
            $scope.hourHeight = tops[1] - tops[0] || $scope.hourHeight
            return $scope.offsets
        $scope.getOffsets = (name, hourSpan) ->
            if not $scope.offsets[name]
                # if for some reason we don't have any data on that name,
                # return something sensible...
                ret =
                    left: 10
                    width: 50
                    bottom: hourSpan.end*20
                    top: hourSpan.start*20
                return ret

            
            # linearly interpolate values using the keys
            # of values as the xs and the value of values as
            # the ys
            interpolateTime = (hour, values) ->
                x1 = Math.floor(hour)
                x2 = Math.ceil(hour)

                if x1 == x2
                    return values[hour]
                if not (values[x1]? and values[x2])
                    return undefined

                delta = values[x2] - values[x1]
                decimal = hour - x1
                return values[x1] + decimal*delta


            offsets = $scope.offsets[name]
            hours = Object.keys(offsets.tops)
            minHour = Math.min(hours...)
            maxHour = Math.max(hours...)
            
            # set up the return bounds 
            # with defaults
            ret =
                left: offsets.left
                width: offsets.width
                bottom: offsets.tops[maxHour]
                top: offsets.tops[minHour]


            # compute the top and bottom offset as the linear interpolation
            # betwen the nearest hours
            ret.bottom = interpolateTime(hourSpan.end, offsets.tops) || ret.bottom
            ret.top = interpolateTime(hourSpan.start, offsets.tops) || ret.top

            return ret
        
        # compute the largest time interval
        # a timespan can occupy centered at initTime
        # if ignoreRange is set, then that time interval
        # is treated as if it isn't there
        $scope.computeValidTimeRange = (person, initTime, ignoreRange={}) ->
            useableIntervals = (i for i in person.times when (i.start != ignoreRange.start and i.end != ignoreRange.end))
            
            end = Math.min.apply(null, (i.start for i in useableIntervals when (i.start >= initTime)))
            end = Math.min(26, end)     # fix these hardcoded values
            start = Math.max.apply(null, (i.end for i in useableIntervals when (i.end <= initTime)))
            start = Math.max(-3, start)

            return {start: start, end: end}

        $scope.$on 'onLastRepeat', ->
            $scope.computeOffsets()
            $scope.$broadcast('offsetsComputed', $scope.offsets)
        
        window.sss = $scope
        return
app.directive('dayTable', dayTableWidget)


hourspanWidget = ->
    templateUrl: 'hourspan.tmpl.html'
    restrict: 'E'
    scope:
        span: '='
        person: '='
    link: (scope, elm, attr) ->
        scope.container = elm.find('.hourspan-container')

        # set up the drag and drop adjustability
        oldHourChange = null
        startY = null
        origTimeStart = scope.span.start
        origTimeEnd = scope.span.end

        
        bounds = scope.$parent.computeValidTimeRange(scope.person, (origTimeStart+origTimeEnd)/2, {start: origTimeStart, end: origTimeEnd})
        
        top = interact($(elm).find('.drag-handle.top')[0])
        top.draggable({max: Infinity})
        top.on 'dragstart', (evt) ->
            startY = evt.pageY
            origTimeStart = scope.span.start
            origTimeEnd = scope.span.end
            bounds = scope.$parent.computeValidTimeRange(scope.person, (origTimeStart+origTimeEnd)/2, {start: origTimeStart, end: origTimeEnd})
        top.on 'dragmove', (evt) ->
            hourHeight = scope.$parent.hourHeight
            delta = startY - evt.pageY

            hourChange = roundToHalf(delta/hourHeight)
            # if we drag enough to change the number of hours we span, update everything
            if hourChange != oldHourChange
                oldHourChange = hourChange
                startHour = origTimeStart - hourChange
                # make sure we stay in bounds
                startHour = Math.max(startHour, bounds.start)
                # make sure we don't cross over ourself
                startHour = Math.min(startHour, origTimeEnd - .5)
                scope.span.start = startHour
                scope.$apply()
        
        bottom = interact($(elm).find('.drag-handle.bottom')[0])
        bottom.draggable({max: Infinity})
        bottom.on 'dragstart', (evt) ->
            startY = evt.pageY
            origTimeEnd = scope.span.end
            origTimeStart = scope.span.start
            bounds = scope.$parent.computeValidTimeRange(scope.person, (origTimeStart+origTimeEnd)/2, {start: origTimeStart, end: origTimeEnd})
        bottom.on 'dragmove', (evt) ->
            hourHeight = scope.$parent.hourHeight
            delta = startY - evt.pageY

            hourChange = roundToHalf(delta/hourHeight)
            # if we drag enough to change the number of hours we span, update everything
            if hourChange != oldHourChange
                oldHourChange = hourChange
                endHour = origTimeEnd - hourChange
                # make sure we stay in bounds
                endHour = Math.min(endHour, bounds.end)
                # make sure we don't cross over ourself
                endHour = Math.max(endHour, origTimeStart + .5)
                scope.span.end = endHour
                scope.$apply()
        return

    controller: ($scope) ->
        resize = ->
            offests = $scope.$parent.getOffsets($scope.person.name, $scope.span)
            css =
                left: offests.left
                width: offests.width
                height: offests.bottom - offests.top
                top: offests.top
            $scope.container.css(css)
        
        # deep watch span
        $scope.$watch('span', resize, true)
        $scope.$on 'offsetsComputed', ->
            resize()
app.directive('hourspan', hourspanWidget)

#
# Directive that fires an even on the last instance of an ng-repeat
#

onLastRepeat = ->
    restrict: 'A'
    link: (scope, element, attr) ->
        if scope.$last
            window.setTimeout ->
                scope.$emit('onLastRepeat', element, attr)
app.directive('onLastRepeat', onLastRepeat)

###
# Helper functions
###

# creates a list with {thisday: <is ti the current day>, hour: <current hour>}
# with 0 = 12AM current day
createHourList = (start=-2, end=24+4) ->
    today = (t) -> if 0 <= i < 24 then "today" else "not-today"
    hour = (t) -> "#{if t %% 12 == 0 then 12 else (t%%12)}#{if t %% 24 >=12 then 'pm' else 'am'}"
    return ({thisday: today(i), hour: hour(i), time: i} for i in [start...end])

roundToHalf = (t) ->
    return Math.round(2*t)/2
