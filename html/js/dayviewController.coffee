
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

createFakeHangoutData = (start=new Date(2015,1,1), end=new Date(2016, 1, 1), people=['Andrei', 'Andrew', 'Jonah', 'Paul']) ->
    ret = {}
    curr = new Date(start)
    while curr <= end
        todaysHangouts = {}

        numHangouts = randRange(0, people.length)
        hangouts = randSample(people, numHangouts)
        for person in hangouts
            day = []
            segments = randRange(1,2)
            if segments > 1
                startT = randRange(0,23)
                endT = randRange(startT+1, 24)
                # divide by two so we get half-hours
                day.push({start: startT/2, end: endT/2})
                startT = randRange(endT+1,48)
                endT = randRange(startT+1, 48)
                # divide by two so we get half-hours
                day.push({start: startT/2, end: endT/2})
            else
                startT = randRange(0,48)
                endT = randRange(startT+1, 48)
                # divide by two so we get half-hours
                day.push({start: startT/2, end: endT/2})
            todaysHangouts[person] =
                name: person
                times: day
        ret[curr] = todaysHangouts

        curr.setDate(curr.getDate()+1)
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

    window.xxx = dataService

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
