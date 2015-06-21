###
# START OF THE APP
###
app = angular.module('statsControllers', [])


###
# StatsController
###
statsController = ($scope, $routeParams, dataService) ->
    $scope.downloadData = ->
        console.log 'hi'
        data = dataService.collection.find()
        fileName = "timeTrackerData.json"
        dataStr = JSON.stringify(data, null, 4)

        blob = new Blob([dataStr], {type: 'application/json'})
        window.saveAs(blob, fileName)

        #downloadManager = new DownloadManager(fileName, dataStr, 'application/json')
        #downloadManager.download()
    $scope.$watch 'loadedData', ->
        try
            data = JSON.parse($scope.loadedData)
        catch e
            return
        # if we got data valid JSON, clear the collection and set the data
        console.log('overridding saved data')
        dataService.collection.setData(data)
        dataService.collection.save()
        
    return
app.controller('StatsController', ['$scope', '$routeParams', 'dataService', statsController])

fileread = ->
    scope:
        fileread: '='
    link: (scope, elm, attrs) ->
        elm.bind 'change', (evt) ->
            reader = new FileReader
            reader.onload = (loadEvt) ->
                scope.$apply ->
                    scope.fileread = loadEvt.target.result
            reader.readAsText(evt.target.files[0])

app.directive('fileread', fileread)
