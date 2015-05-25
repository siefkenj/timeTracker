
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
    $scope.people =
        'Andrew': { name: 'Andrew', times: [{start:10, end:12}, {start:4, end:8}] },
        'Seth': { name: 'Seth', times: [{start:4, end:8}] },
        'Paul': { name: 'Paul', times: [{start:14, end:15.5}] },
    

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
    link: (scope, elm, attr) ->
        scope.container = elm
        scope.hoverElm = $(elm).find('.new-hourspan-hover')

        $(elm).on 'click', (evt) ->
            target = evt.target
            # find if we clicked on any child of a valid
            # hour column
            parent = $(target).closest('.hour[x-name]')[0]
            if parent?
                name = parent.getAttribute('x-name')
                hour = parseInt(parent.getAttribute('x-hour'), 10)
                person = scope.people[name]
                
                scope.newTime(person, hour)
                scope.showHover = false
                scope.$apply()

        $(elm).on 'mousemove', (evt) ->
            target = evt.target
            oldHover = scope.showHover
            # find if we clicked on an empty hour row
            parent = $(target).closest('.hour[x-name]')[0]
            if parent?
                # don't reparent if we are a child
                if not $(target).closest('.new-hourspan-hover')[0]
                    $(target).append(scope.hoverElm)

                scope.showHover = true
            else
                scope.showHover = false

            # if we're not hoverable, we don't want to show nomatter what
            if not $(parent).hasClass('hoverable')
                scope.showHover = false

            # angular is watching a lot of things, only tell it to digest if we need to
            if oldHover != scope.showHover
                scope.$apply()

        $(elm).on 'mouseleave', (evt) ->
            oldHover = scope.showHover
            scope.showHover = false
            # angular is watching a lot of things, only tell it to digest if we need to
            if oldHover != scope.showHover
                scope.$apply()

    controller: ($scope) ->
        $scope.showHover = false

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

            for _,person of $scope.people
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
        # adds a new timespan to `person` of a fixed duration
        # attempting to have the result start at hour `hour`.
        # If it cannot start at `hour` (because another timespan
        # is in the way), the start and end time will be adjusted
        # to keep the duration `defaultDuration`
        $scope.newTime = (person, hour, defaultDuration=2) ->
            range = $scope.computeValidTimeRange(person, hour)
            # create a new range that defaults to defaultDuration hours 
            # but is garunteed to remain in the bounds of range
            newRange =
                start: hour
                end: hour + defaultDuration
            newRange.end = Math.min(newRange.end, range.end)
            newRange.start = newRange.end - defaultDuration
            newRange.start = Math.max(newRange.start, range.start)
            
            person.times.push(newRange)
            return

        $scope.$on 'onLastRepeat', ->
            console.log 'last'
            $scope.computeOffsets()
            $scope.$broadcast('offsetsComputed', $scope.offsets)

        $scope.makeHoverable = (choice=true) ->
            if choice
                $($scope.container).find('.hour[x-name]').addClass('hoverable')
            else
                $($scope.container).find('.hour[x-name]').removeClass('hoverable')
            return
        
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
        topDragStart = (evt) ->
            startY = evt.pageY
            origTimeStart = scope.span.start
            origTimeEnd = scope.span.end
            bounds = scope.$parent.computeValidTimeRange(scope.person, (origTimeStart+origTimeEnd)/2, {start: origTimeStart, end: origTimeEnd})
            
            # make sure we don't accidentally trigger
            # unwanted hover events on the parent
            scope.$parent.makeHoverable(false)
        topDragMove = (evt) ->
            evt.preventDefault()
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
        topDragEnd = (evt) ->
            # restore hover functionality
            scope.$parent.makeHoverable(true)
        top.on('dragstart', topDragStart)
        top.on('dragend', topDragEnd)
        top.on('dragmove', topDragMove)

        # make the remove button act like a drag handle when it is dragged
        top = interact($(elm).find('.remove-button')[0])
        top.draggable({max: Infinity})
        top.on('dragstart', topDragStart)
        top.on('dragend', topDragEnd)
        top.on('dragmove', topDragMove)

        
        bottom = interact($(elm).find('.drag-handle.bottom')[0])
        bottom.draggable({max: Infinity})
        bottom.on 'dragstart', (evt) ->
            startY = evt.pageY
            origTimeEnd = scope.span.end
            origTimeStart = scope.span.start
            bounds = scope.$parent.computeValidTimeRange(scope.person, (origTimeStart+origTimeEnd)/2, {start: origTimeStart, end: origTimeEnd})
            
            # make sure we don't accidentally trigger
            # unwanted hover events on the parent
            scope.$parent.makeHoverable(false)
        bottom.on 'dragend', (evt) ->
            # restore hover functionality
            scope.$parent.makeHoverable(true)
        bottom.on 'dragmove', (evt) ->
            evt.preventDefault()
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
            height = offests.bottom - offests.top
            css =
                height: height
                top: offests.top
            $scope.container.css(css)
            # if we get too short, we'll add the compact class
            if height < 50
                $scope.container.addClass('compact')
            else
                $scope.container.removeClass('compact')
        
        $scope.remove = ->
            for r,i in $scope.person.times
                if r.start == $scope.span.start and r.end == $scope.span.end
                    removeIndex = i
            if removeIndex?
                $scope.person.times.splice(removeIndex, 1)

            if $scope.person.times.length == 0
                delete $scope.$parent.people[$scope.person.name]
            return


        # deep watch span
        $scope.$watch('span', resize, true)
        $scope.$on('offsetsComputed', resize)


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
