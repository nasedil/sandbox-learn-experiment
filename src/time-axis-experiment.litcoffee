Timeline axis in CoffeeScript
=============================

Table of Contents
-----------------

 1. [Introduction and description](#introduction-and-description)
 2. [Test cases](#test-cases)
 3. [Development concerns](#development-concerns)
 4. [Library implementation](#library-implementation)
    1. [The `TimelineMaker` class](#the-timelinemaker-class)
 5. [Library tests](#library-tests)
 6. [Examples](#examples)
 7. [Notes](#notes)

------------------------------------------------------------

Introduction and description
----------------------------

This demo is aimed at exploring possibilities of visualizing time axis.  This especially applies to situations where time axis is meant to be used in interactive plotting, being able to change from very short time intervals to very long time intervals.

Main points of usability of the timeline are:
 * Area that the timeline takes (ideally, as little as possible).
 * Clarity and readability (ideally text/info should be concise and distinctive).
 * How much information is showed (ideally, as much as current zoom level and resolution can afford).
 * Should be easily navigable (should work also for visually impaired).
 * Should be interactive (ideally react according to its representation).

Test cases
----------

### Visual test cases

 1. All time labels and ticks should correspond to their times
 2. Daylight-saving time should be displayed correctly
 3. Leap seconds should be displayed properly
 4. Every interval type should be displayed properly
   1. year
   2. month
   3. week
   4. day
   5. hour
   6. minute
   7. second
   8. millisecond
 5. Check that lines and text are sharp
 6. There should be no intersection of features

### Unit test cases

To be done:
 * Labels should not intersect with each other
 * There should be at least one label (or no?)
 * Label should be in range if its coordinates are in viewport
 * Check for daylight-saving time
 * Check for daylight-saving time table for several historical intervals
 * Check for leap seconds

Development concerns
--------------------

### Readability

The following things should be thought of before making a final version:
 * DPI should be taken into account.  It should work fine on any DPI display.
 * Every element should be separated from others.
    * Visual elements should not intersect with each other.
    * Visual elements such as labels and ticks should be at some good distance to each other.
 * It is a good idea to alternate colors of intervals.
    * Use two colors.
    * They should differ for visually impaired.
    * And should be suitable for grey-color display.
    * Thus, they should differ in brightness at least.
 * Continuos change (opposed to discrete) between scales (that is zoom levels).
    * Makes it possible to animate without jumps between representation levels, keeping viewer connection to details.
    * Adds more information to viewer.  A question is how to keep this simple enough and not bloated with information and graphics.

### Portability

To make it more flexible to render (to canvas, svg, vega, anything else), we should have an intermediate object as output of axis formatting, which could be rendered after withe a chosen rendeder.

------------------------------------------------------------

Library implementation
----------------------

### The `TimelineMaker` class

Since formatting and rendering of timeline involves a lot of calculations, it is divided in several functions, and they are combined in the `TimelineMaker` class.

#### The `TimelineMaker()` constructor

The `options` parameter is a dictionary with values that are needed for formatting timeline:
 * `options.tickLength`:  length (in pixels) of tick from baseline downwards.
 * `options.intervalType`:  base interval that is displayed (should be integral); can be on of 'year', 'month', 'week', 'day', 'hour', 'minute', 'second', 'millisecond'.
 * `options.labelPlacement`:  'point' or 'interval';  the first is for putting text labels under corresponding ticks, the second is for putting text labels between ticks (that is under intervals).
 * `options.intervalMultiplier`:  number of base intervals that should be skipped between consequent ticks.


    class TimelineMaker
      constructor: (@options) ->

The two functions that are intended to be called are `formatTimeAxis()`, which formats time axis into a dictionary that describes the look of axis, and one of the `renderTo...` functions that render that data dictionary to a desired context.

#### The `formatTimeAxis()` function

A function that formats time axis into an intermediate format.  It has two parameters:
 * `interval`:  a dictionary with `start` and `end` values, each of `Date` type.
 * `width` is the corresponding to that interval width of a viewport.

It returns a formatted time axis object.  This object is a collection of features with their coordinates in a viewport (the top left point of the viewport is (0,0), the top-right is (0, width)).

      formatTimeAxis: (interval, width) ->
        {@start, end} = interval
        @intervalLength = end - @start
        @width = width

We can put on axis ticks and labels, and also colour areas between them.  They correspond to a set of time points.  Labels could correspond to time points or to time intervals between these points.

Ticks should correspond to _edge points_ of time, a point of time between two days (00-00), two years, months, weeks, or a sharp time point, having integer number of hours, or minutes, or seconds.  In general, while moving from bigger to smaller time interval types, every interval type has to be in integer amount, until  some point.  For example (10 years, 2 months, 3 days) from Epoch and remainder which is less than one day.  That means whe should have a parameter that corresponds to the smallest time interval that has to be integral.  We call this parameter _options.intervalType_.  We also need a number of this intervals between each tick.  This parameter will be `options.intervalMultiplier`.  There is one exception though:  in case of weeks there is no previous integral interval.  So there are two cases:  week and (year, month, day, hour, minute, second, millisecond).

So we need to build a list of time points that correspond to a given time interval.  We will put such code in a special function, `findPointList()`.

        pointList = @findPointList @start, end

Now, when we have found the list of time points, we need to construct a dictionary with graphical elements (features).  To transform time value into a coordinate we use the `timeToCoord()` function.  We start with ticks.  Each tick is a line.  The @options.tickLength parameter is a base length of a tick.  We assume that (y = 0) is a baseline and tick length is from baseline to `@options.tickLength` down and `@options.tickLength/5` up.

We store ticks and other lines in `lines` element of the dictionary.

        ticks = for timePoint in pointList
          {
            x1: @timeToCoord timePoint
            x2: @timeToCoord timePoint
            y1: -@options.tickLength / 5
            y2: @options.tickLength
          }

We also add axis (a horizontal line).

        axisLine = {
          x1: 0
          x2: @width
          y1: 0
          y2: 0
        }

Now we construct a list of text features, each has coordinates and string.

_Note_:  here we also need to improve formatting, now it's just a quick fix to display text.  Text should be formatted without problems on any display and resolution and shouldn't intersect ticks when it has reasonable font size.

Text labels can be basically displayed in two ways.  The first one is to put label right under the tick, so that lable corresponds to time or date at this point.  Another way is to put label between ticks so that it corresponds to time interval between these two ticks.  For me it seems quite rational to use the first way to show times, and the second way to show days, months and years;  this is in case of general timeline, that we can move and zoom, and without a need to highlight particular dates.  To clarify what I mean we can consider a typical time axis in pretty much any library these days.  When zoomed out a lot, it usually shows ticks at times like 00:00, at first day of month or a year.  This is pretty logical.  But then, usually a label is shown under such tick, for examle a label of a month that starts at this point of time.  Which doesn't make much sense, because a month is a period.  When we say 'in November', we usually mean 'some time between start and end of November' (unlike when we say 'at 3', which usually means 'at 3:00').  But if the label is under 00:00 of 1st of November, it looks for a viewer like november corresponds to some time from mid-October to mid-November.  Which is very confusing and misleading too.  On the other side, showing the 'November' label in the middle of November on an axis corrects this.  This is a motivation for making two types of label positioning in our timeline implementation:  _point_ and _interval_.  They are determined by `options.labelPlacement` ('point' or 'interval').

To do it we first make a list of text labels assuming point label placement.

        textLabels = for timePoint in pointList
          {
            x: @timeToCoord timePoint
            y: @options.tickLength * 1.2
            text: switch @options.intervalType
              when 'year' then timePoint.getFullYear().toString()
              when 'month' then timePoint.getMonth().toString()
              when 'week', 'day' then timePoint.getDate().toString()
              when 'hour' then timePoint.getHours().toString()
              when 'minute' then timePoint.getMinutes().toString()
              when 'second' then timePoint.getSeconds().toString()
              when 'millisecond' then timePoint.getMilliseconds().toString()
          }

Then, if `options.labelPlacement` is equal to 'interval', we remove the last item and adjust x coordinates of other items.

_Note_: one could thing of better implementation here.  I tried to make it shorter and came to the current solution.

        for textLabel, i in textLabels when i isnt (textLabels.length-1)
          textLabel.x = (textLabel.x + textLabels[i+1].x) / 2
        textLabels.pop()

Now we combine all elements into a one dictionary and return it.

        features =
          lines: ticks.concat axisLine
          textLabels: textLabels

#### The `findPointList()` function

This function returns a list of points that are needed to be calculated for an interval:
 * `start`:  when the interval starts, `Date` object.
 * `end`:  when interval ends, `Date` object.

It returns a list of `Date` objects.

      findPointList: (start, end) ->

Since we could need labels between time points, we need time points inside the interval (non-inclusive) and one point on left and right side.  We can build the point list by finding the leftmost _edge point_ which is strictly less than the `start` of the interval.  We move code that does that to the `findLeftTime()`.

        timePoint = @findLeftTime start

Then, we populate the list in by incrementing points until the we reach right end of the interval, using `findNextPoint()` function.

        pointList = [timePoint]
        until timePoint > end
          timePoint = @findNextPoint timePoint
          pointList.push timePoint
        pointList

#### The `findLeftTime()` function

The `findLeftTime()` function calculates the rightmost point of time for current `options.intervalType` such that it is not greater than a given point of time.  The `options.intervalType` could be one of the following:
 * 'year'
 * 'month'
 * 'week'
 * 'day'
 * 'hour'
 * 'minute'
 * 'second'
 * 'millisecond'

Another option, `options.intervalMultiplier`, says how many of such intervals are between two time points.  It should be an integer value.  For years and months we truncate them to the desired value, while for days and weeks we will count from a fixed origin day near Epoch (Monday 5 january 1970), so that any day intervals are independent from underlying months and years.  That also means that in case of months the `options.intervalMultiplier` should be equal to 1, 2, 3, 4 or 6 to be displayed correctly.  To calculate number of days or weeks (reduced to 7 calculation for 7 days) from origin day we use binary subtracting, starting from huge multiplier equal to 1048576 (roughly 2800/11200 years), going down to base multiplier equal to 1.  For interval types smaller or equal than hours we use the `findNextPoint()` function by incrementing local origin (the interval type and everything smaller is reset to 0).  This is done to avoid problems with daylight-saving and similar things.  In `findNextPoint()` we make sure that edge points are consistent while using different values of `start`.

Function arguments:
 * `start`:  a point of time, `Date` object.

It returns a `Date` object.

      findLeftTime: (start) ->
        leftTime = new Date start.getTime()
        switch @options.intervalType
          when 'year'
            newYear = start.getFullYear() - start.getFullYear() % @options.intervalMultiplier
            leftTime.setFullYear newYear, 0, 1
            leftTime.setHours 0, 0, 0, 0
          when 'month'
            newMonth = start.getMonth() - start.getMonth() % @options.intervalMultiplier
            leftTime.setMonth newMonth, 1
            leftTime.setHours 0, 0, 0, 0
          when 'week', 'day'
            leftTime.setFullYear 1970, 0, 5
            leftTime.setHours 0, 0, 0, 0
            delta = 1048576
            intervalMultiplier = @options.intervalMultiplier
            if @options.intervalType is 'week'
              intervalMultiplier *= 7
            while delta >= 1
              nextTime = new Date leftTime.getFullYear(),
                leftTime.getMonth()
                leftTime.getDate() + delta*intervalMultiplier
                leftTime.getHours()
                leftTime.getMinutes()
                leftTime.getSeconds()
                leftTime.getMilliseconds()
              delta /= 2
              leftTime = nextTime if nextTime <= start
          when 'hour'
            leftTime.setHours 0, 0, 0, 0
            while leftTime < start
              nextTime = @findNextPoint leftTime
              leftTime = nextTime if nextTime <= start
          when 'minute'
            newMinutes = start.getMinutes() - start.getMinutes() % @options.intervalMultiplier
            leftTime.setMinutes newMinutes, 0, 0
          when 'second'
            leftTime.setSeconds start.getSeconds(), 0
            while leftTime < start
              nextTime = @findNextPoint leftTime
              leftTime = nextTime if nextTime <= start
          when 'millisecond'
            newMilliseconds = start.getMilliseconds() - start.getMilliseconds() % @options.intervalMultiplier
            leftTime.setMilliseconds newMilliseconds
        leftTime

There is a code repetition in the switch statement above.  One can think of a good way to improve this part of code.

### The `findNextPoint()` function

This function calculates next edge time point for a current options assuming `timePoint` argument is an edge time point.  We take care of daylight-saving time and leap seconds here, assuming that at most one hour/minute/second/millisecond is added or subtracted.  Also we assume that subtraction is not happening at time with 0 value, that is something like 00 -> 23 is not happening.

In current implementation we cope with daylight-saving time by adding hours in UTC to date and then checking how the value changes in local time and fixing by one hour if needed.  The same for leap seconds.

Function arguments:
 * `timePoint`:  current edge time point, `Date` object.

It returns a `Date` object.

      findNextPoint: (timePoint) ->
        nextTime = new Date timePoint.getTime()
        switch @options.intervalType
          when 'year'
            nextTime.setFullYear (timePoint.getFullYear() + @options.intervalMultiplier)
          when 'month'
            nextTime.setMonth (timePoint.getMonth() + @options.intervalMultiplier)
          when 'week'
            nextTime.setDate (timePoint.getDate() + 7*@options.intervalMultiplier)
          when 'day'
            nextTime.setDate (timePoint.getDate() + @options.intervalMultiplier)
          when 'hour'
            nextTime.setUTCHours (timePoint.getUTCHours() + @options.intervalMultiplier)
            hours = nextTime.getHours()
            if hours % @options.intervalMultiplier isnt 0
              if (hours+1) % @options.intervalMultiplier is 0
                nextTime.setUTCHours (nextTime.getUTCHours() + 1)
              else
                nextTime.setUTCHours (nextTime.getUTCHours() - 1)
          when 'minute'
            nextTime.setMinutes (timePoint.getMinutes() + @options.intervalMultiplier)
          when 'second'
            nextTime.setUTCSeconds (timePoint.getUTCSeconds() + @options.intervalMultiplier)
            seconds = nextTime.getSeconds()
            if seconds % @options.intervalMultiplier isnt 0
              if (seconds+1) % @options.intervalMultiplier is 0
                nextTime.setUTCSeconds (nextTime.getUTCSeconds() + 1)
              else
                nextTime.setUTCSeconds (nextTime.getUTCSeconds() - 1)
          when 'millisecond'
            nextTime.setUTCMilliseconds (timePoint.getUTCMilliseconds() + @options.intervalMultiplier)
        nextTime

#### The `timeToCoord()` function

To get coordinate of time point we use `@intervalLength` that we stored in `formatTimeAxis()`, which is equal to the number of milliseconds between `end` and `start` of the interval.  We use it to calculate pixe/time ratio, equal to `@width / @intervalLength`.

Function arguments:
 * `time`:  time point, `Date` object.

It returns a number between 0 and `@width`.

      timeToCoord: (time) ->
        timeFromStart = time - @start
        coordinate = timeFromStart * @width / @intervalLength

#### The `renderToCanvas()` function

This function renders formatted time axis to html canvas.
 * `axisData` is formatted data (that we get by calling any of the `format...()` functions)
 * `canvas` is a html canvas object on which axis is drawn
 * `left` and `top` are x- and y-coordinates of the canvas that correspond to the (0, 0) point of the axis viewport


      renderToCanvas: (axisData, canvas, left, top) ->

In the beginning we do just regular initialization of context and its properties.  We also wrap our drawing code into `save()` and `restore()` to not alter context properties globally.

        context = canvas.getContext '2d'
        context.save()
        context.strokeStyle = '#000000'
        context.fillStyle = '#000000'
        context.lineWidth = 1
        context.font = 'normal 12px sans-serif'
        context.textAlign = 'center'
        context.textBaseline = 'top'

Instead of writing the same code again when we need canvas coordinates we define an additional nested function `translateCoord()` that turns logical corrdinates into canvas coordinates.

        translateCoord = (coordX, coordY) =>
          newCoord = [
            @roundForCanvas(left + coordX)
            @roundForCanvas(top + coordY)
          ]

To all drawing functions we pass coordinates altered by `roundForCanvas()` function, which rounds values in such a way that lines are more sharp.

        context.beginPath()
        for line in axisData.lines
          [x1, y1] = translateCoord(line.x1, line.y1)
          [x2, y2] = translateCoord(line.x2, line.y2)
          context.moveTo x1, y1
          context.lineTo x2, y2
        context.stroke()

        for textLabel in axisData.textLabels
          x = left + textLabel.x
          y = top + textLabel.y
          context.fillText textLabel.text, x, y

        context.restore()

#### The `roundForCanvas()` function

This function may be used to avoud aliasing of lines, especially on low-resolution displays.  It rounds coordinate to middle-pixel values, which are .5 in case of html canvas.

      roundForCanvas: (coord) ->
        0.5 + Math.round(coord-0.5)

Library tests
-------------

------------------------------------------------------------

Examples
--------

Before we display anytihng, we define a function that colors background of canvas in some color, to erase before rendering axis, and to make canvas area easily visible.

    recleanCanvas = ->
      canvas = document.getElementById 'timeline'
      context = canvas.getContext '2d'
      context.fillStyle = '#77FFBB'
      context.fillRect(0, 0, canvas.clientWidth, canvas.clientHeight)

The `getMousePos` function gives mouse position relative to a `canvas`.

    getMousePos = (canvas, event) ->
      rect = canvas.getBoundingClientRect()
      {
        x: event.clientX - rect.left
        y: event.clientY - rect.top
      }

This simple code displays time axis when html page is loaded, in `timeline` canvas element.

    makeDemo = ->
      canvas = document.getElementById 'timeline'
      recleanCanvas()
      timelineMaker = new TimelineMaker
        tickLength: 25
        intervalType: 'day'
        labelPlacement: 'interval'
        intervalMultiplier: 1
      start = new Date('2015-06-15T00:00:00')
      end = new Date('2015-07-13T15:23:49')
      axisData = timelineMaker.formatTimeAxis {start, end}, canvas.width
      timelineMaker.renderToCanvas axisData, canvas, 0, 15

Wa also add mouse tracking functionality to test our timeline.  When mouse is pressed we can change time interval by dragging mouse.

      dragging = false
      oldX = 0
      oldY = 0
      document.getElementById('timeline').onmousedown = (event) ->
        dragging = true
        canvas = document.getElementById 'timeline'
        {x: oldX, y: oldY} = getMousePos(canvas, event)

      document.getElementById('timeline').onmouseup = (event) ->
        dragging = false

      document.getElementById('timeline').onmousemove = (event) ->
        if dragging
          canvas = document.getElementById 'timeline'
          {x: clientX, y: clientY} = getMousePos(canvas, event)
          deltaX = event.clientX - oldX
          deltaY = event.clientY - oldY
          oldX = event.clientX
          oldY = event.clientY

Now we calculate how much time we should move.

          timeInterval = end - start
          timeDelta = - deltaX * timeInterval / canvas.clientWidth
          start = new Date (start.getTime() + timeDelta)
          end = new Date (end.getTime() + timeDelta)

And render it again.

          recleanCanvas()
          axisData = timelineMaker.formatTimeAxis {start, end}, canvas.width
          timelineMaker.renderToCanvas axisData, canvas, 0, 15

The same for mouse wheel:  we change `intervalLength` when wheel is scrolled.  We keep the same time value under mouse pointer before and after zooming.  This is done by multiplying interval before point and after point by zooming multiplier.  So if mouse point has time P and our interval is _(P - A, P + B)_ it becomes after zoom _(P - A*m, P + B*m)_, where _m_ is the multiplier.

        base = 1.05
        document.getElementById('timeline').onwheel = (event) ->
          canvas = document.getElementById 'timeline'
          multiplier = Math.pow(base, event.deltaY)
          timeInterval = end-start
          {x: clientX, y: clientY} = getMousePos(canvas, event)

In the next line we subtract `0.5` to correct mouse x offset, though it is strange that we need to subtract it.  But it works better, so we keep it as a quick fix.

          leftInterval = (clientX-0.5) * timeInterval / canvas.clientWidth
          rightInterval = timeInterval - leftInterval
          mousePoint = start.getTime() + leftInterval
          leftInterval *= multiplier
          rightInterval *= multiplier
          start = new Date(mousePoint - leftInterval)
          end = new Date(mousePoint + rightInterval)

          recleanCanvas()
          axisData = timelineMaker.formatTimeAxis {start, end}, canvas.width
          timelineMaker.renderToCanvas axisData, canvas, 0, 15

We run the `makeDemo` function when page loads.

    window.onload = makeDemo

------------------------------------------------------------

Notes
-----

### Notes related to only this file

Well, no notes yet.

### Notes that should be moved away at some point

These notes are currently a draft of coding style, tricks and ideas that could be used in every CoffeeScript file.

Important notes:
 * Between a bullet list and code block there should be at lest 2 empty lines, otherwise code is not formatted correctly in Github.  However, it compiles without problem and works as it should.  This is probably a Github's bug.
 * Use 60 dashes to include a horizontal line.  That makes horizontal line easily viewable in an editor too.
 * Limit line to 79 characters, at least code (text could be soft-wrapped).  That improves readability, even though screens are large these times.  Also it makes possible to view several documents on one screen.
