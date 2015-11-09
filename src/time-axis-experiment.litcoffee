Timeline axis in CoffeeScript
=============================

Abstract
--------

This file contains an experimental implementation of time axis visualization in literate CoffeeScript.  Description is followed by source code with explanations and small demo examle.  The main classes are exported as a Node module.

Table of Contents
-----------------

 1. [Introduction and description](#introduction-and-description)
 2. [Test cases](#test-cases)
 3. [Development concerns](#development-concerns)
 4. [Library implementation](#library-implementation)
    1. [The `TimeAxisMaker` class](#the-timeaxismaker-class)
    2. [The `TimeAxisRenderer` class](#the-timeaxisrenderer-class)
    3. [Node module exports](#node-module-exports)
 5. [Library tests](#library-tests)
 6. [Examples](#examples)
 7. [Information](#information)
    1. [Authors](#authors)
    2. [License](#license)
    3. [Version history](#version-history)
 8. [Notes](#notes)

------------------------------------------------------------

Introduction and description
----------------------------

### Our reasons and objectives ###

 * Try [CoffeeScript](http://coffeescript.org/)
 * Try [Literate Programming](https://en.wikipedia.org/wiki/Literate_programming)
 * Reimplement time axis and try new visual and technical ideas

### Description ###

Here we try to implement a time axis visualization that would be more readable and at the same time more informative than conventional and widespread time axes.  The main two ideas are:
 * Representing days, months and years as intervals, as opposed to points in time.
 * Layering labels, keeping hours, minutes and seconds on one layer, and days to years on other layers.

### Thoughts ###

This demo is aimed at exploring possibilities of visualizing time axis.  This especially applies to situations where time axis is meant to be used in interactive plotting, being able to change from very short time intervals to very long time intervals (when a user zooms and drags a corresponding plot).

Main points of usability of timeline are:
 * Area that the timeline takes (ideally, as little as possible).
 * Clarity and readability (ideally text/info should be concise and distinctive).
 * How much information is showed (ideally, as much as current zoom level and resolution can afford).
 * Should be easily navigable (should work also for visually impaired).
 * Should be interactive (ideally react according to its representation).

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

### Notes for a reader

If something is not clear, please try to look in the [Dictionary](#dictionary) section first, where commonly used here terms are explained.  Also, there is a [Frequently Asked Questions](#frequently-asked-questions) section.  If something is still unclear or if you think you have found a bug or a mistake, please do not hesitate to write to [Eugene](https://github.com/nasedil/).

Testing
-------

The implementation should be tested.  We need to decide and implement testing system.

### Visual test cases ###

Final version of this time axis implementation should work correctly in the following visual test cases:
 1. All time labels and ticks should correspond to their times
 2. Daylight-saving time should be displayed correctly
 3. Leap seconds should be displayed properly
 4. Every interval type should be displayed properly
   1. year and longer
   2. month
   3. week
   4. day
   5. hour
   6. minute
   7. second
   8. millisecond and shorter
 5. Check that lines and text are sharp
 6. There should be no intersection of features (ticks and text labels)

### Unit test cases ###

We should try to unit-test our code.  Here is a draft of test cases.

 * Labels should not intersect with each other
 * There should be at least one label (or no?)
 * Label should be in range if its coordinates are in viewport
 * Check for daylight-saving time
 * Check for daylight-saving time table for several historical intervals
 * Check for leap seconds

Development concerns
--------------------

### Portability ###

To make it more flexible to render (to canvas, svg, vega, anything else), we have an intermediate object as output of axis formatting, which could be rendered after with a chosen rendeder.  We also can port only one part of code into another library if we need this.  This object consists of features with their properties, for example lines with their coordinates.

------------------------------------------------------------

Library implementation
----------------------

Currently the job of visualizing time axis is split into two steps:  building structure of graphical features (such as lines and text labels) and displaying them (for example on html canvas).  The code for these steps is separated, so that an axis may be displayed using different technologies easily (html canvas, png, webgl, ...).  The first step is done using the `TimeAxisMaker` class, and the second step is done using the `TimeAxisRenderer` class.

The two functions that are intended to be called are `TimeAxisMaker.formatAutomatic()`, which formats time axis into a dictionary that describes the look of axis, and one of the `TimeAxisRenderer.renderTo...` functions that render that data dictionary to a desired context.

### The `TimeAxisMaker` class ###

Since our formatting of time axis involves a lot of calculations, it is separated in several functions, and they are combined in the `TimeAxisMaker` class.

All methods that build axes produce a dictionary with the following elements:
 * A list of lines which includes the following:
    * List of ticks.  Each tick is a vertical line, its position horisontally corresponds some _edge time point_.
    * A horizontal axis line.
 * A list of text labels.  Each label correspond to a time point or a time interval.

Any tick should correspond to an _edge time point_, a point of time between two days (00-00), two years, months, weeks, or a sharp time point, having integer number of hours, or minutes, or seconds.  In general, while moving from bigger to smaller time interval types, every interval type has to be in integer amount, until  some point.  For example 2015 years, 2 months, 3 days and remainder which is less than one day.  That means whe should have a parameter that corresponds to the smallest time interval that has to be integral.  We call this parameter `options.intervalType`.  We also need a number of this intervals between each tick.  This parameter will be `options.intervalMultiplier`.  There is one exception though:  in case of weeks there is no previous integral interval, because a week can start one year and finish the next year.  The `options.intervalType` could be one of the following:
 * 'year'
 * 'month'
 * 'week'
 * 'day'
 * 'hour'
 * 'minute'
 * 'second'
 * 'millisecond'

Another option, `options.intervalMultiplier`, says how many of such intervals are between two time points.  It should be an integer value.

Text labels can be basically displayed in two ways.  The first one is to put label right under the tick, so that lable corresponds to time or date at this point.  Another way is to put label between ticks so that it corresponds to time interval between these two ticks.  For me it seems quite rational to use the first way to show times, and the second way to show days, months and years;  this is in case of general timeline, that we can move and zoom, and without a need to highlight particular dates.  To clarify what we mean we can consider a typical time axis in pretty much any library these days.  When zoomed out a lot, it usually shows ticks at times like 00:00, at first day of month or a year.  This is pretty logical.  But then, usually a label is shown under such tick, for examle a label of a month that starts at this point of time.  Which doesn't make much sense, because a month is a period.  When we say 'in November', we usually mean 'some time between start and end of November' (unlike when we say 'at 3', which usually means 'at 3:00').  But if the label is under 00:00 of 1st of November, it looks for a viewer like november corresponds to some time from mid-October to mid-November.  Which is very confusing and misleading too.  On the other side, showing the 'November' label in the middle of November on an axis corrects this.  This is a motivation for making two types of label positioning in our timeline implementation:  _point_ and _interval_.  They are determined by `options.labelPlacement` ('point' or 'interval').

The exported methods of the class are:
 * `formatAutomatic()`:  builds ticks and labels while automatically deciding what to display.  Only desired label/tick tightness is supplied as an option.
 * `formatFixed()`:  builds ticks and labels with manual setting of parameters.  It should not be used directly, but by other methods, that will be written later.  Is used by `formatAutomatic()`.

The class definition start:

    class TimeAxisMaker

#### The `TimeAxisMaker()` constructor ####

When an object of the class is created, the `options` parameter is passed to it, which is a dictionary with values that are needed for formatting timeline:
 * `options.tickLength`:  length (in pixels) of tick from baseline downwards.
 * `options.intervalType`:  base interval that is displayed (should be integral); can be on of 'year', 'month', 'week', 'day', 'hour', 'minute', 'second', 'millisecond'.
 * `options.labelPlacement`:  'point' or 'interval';  the first is for putting text labels under corresponding ticks, the second is for putting text labels between ticks (that is under intervals).
 * `options.intervalMultiplier`:  number of base intervals that should be skipped between consequent ticks (for example, 3 or 6; could mean 3 or 6 hours, months distance between ticks).
 * `options.tickTailRatio`:  relative size of a tick upwards (so the length of the tick upwards will be `tickTailRatio * tickLength`).
 * `options.axisLineOffset`:  absolute offset downwards of the axis line.
 * `options.labelOffset`:  absolute offset downwards of labels.  A label is drawn centered horisontally and with 'top' baseline.

If some of these options are missing, defaults are supplied:

      constructor: (options) ->
        @options =
          tickLength: options.tickLength ? 10
          tickTailRatio: options.tickTailRatio ? 0.2
          axisLineOffset: options.axisLineOffset ? 0.0
          intervalType: options.intervalType ? 'year'
          labelPlacement: options.labelPlacement ? 'point'
          intervalMultiplier: options.intervalMultiplier ? 1
          labelOffset: options.labelOffset ? 12

_Note_:  I wonder if the code above that assigns default values could be improved.

#### The `formatAutomatic()` function ####

A function that formats time axis.  It is done in two steps:  deciding which _edge time points_ should be used for formatting, and actual formatting.  The second step is done in the `formatFixed()` function.  The first step is done here.

It has two arguments:
 * `interval`:  a dictionary with `start` and `end` values, each of `Date` type.
 * `width`:  the corresponding to that interval width of a viewport.
 * `tightness`:  a number that guides how tightly should be positioned ticks and labels.  Larger values mean more ticks and labels in the same interval.  __Note__:  in the current implementation this number correspoinds to a maximal number of labels shown.

It returns a formatted time axis object.  This object is a collection of features with their coordinates in a viewport (the top left point of the viewport is (0,0), the top-right is (0, width)).

      formatAutomatic: (interval, width, tightness = 5) ->
        {@start, end} = interval
        @intervalLength = end - @start
        @width = width

To decide which interval between _edge time points_ should be used, we increase that interval until we have no more points than is allowed by `tightness`.  Intervals between edge points are defined by a combination of `intervalType` and `intervalMultiplier`.  We store such combinations in the `TimeAxisMaker.intervalsProgression` structure.  We put code that calculates approximate interval between time points for such a combination into the function `TimeAxisMaker.findNominalInterval()` (this is because we can have 28 to 31 days in a month etc).

        intervalTypeIndex = 0
        intervalMultiplierIndex = 0
        currentStepInterval = TimeAxisMaker.findNominalInterval(TimeAxisMaker.intervalsProgression[intervalTypeIndex].type, TimeAxisMaker.intervalsProgression[intervalTypeIndex].multipliers[intervalMultiplierIndex])
        while currentStepInterval * tightness < @intervalLength
          intervalMultiplierIndex += 1
          if intervalMultiplierIndex >= TimeAxisMaker.intervalsProgression[intervalTypeIndex].multipliers.length
            intervalTypeIndex += 1
            intervalMultiplierIndex = 0
          currentStepInterval = TimeAxisMaker.findNominalInterval(TimeAxisMaker.intervalsProgression[intervalTypeIndex].type, TimeAxisMaker.intervalsProgression[intervalTypeIndex].multipliers[intervalMultiplierIndex])

__Note__:  after finding suitable interval we maybe need to adjust it back.  I'm not sure, needs to be investigated.

__Note__:  the stuff above is really ugly.  I need to do something with that.

Now, after we have found right interval, we can call the `formatFixed()` function to do formatting for that interval.  Depending on `intervalType` we choose interval or point label placement.

        @options.intervalType = TimeAxisMaker.intervalsProgression[intervalTypeIndex].type
        @options.intervalMultiplier = TimeAxisMaker.intervalsProgression[intervalTypeIndex].multipliers[intervalMultiplierIndex]
        switch @options.intervalType
          when 'year', 'month', 'week', 'day'
            @options.labelPlacement = 'interval'
          else
            @options.labelPlacement = 'point'
        @formatFixed(interval, width)

#### The `formatFixed()` function ####

A function that formats time axis.  It has two arguments:
 * `interval`:  a dictionary with `start` and `end` values, each of `Date` type.
 * `width`:  the corresponding to that interval width of a viewport.

It returns a formatted time axis object.  This object is a collection of features with their coordinates in a viewport (the top left point of the viewport is (0,0), the top-right is (0, width)).

      formatFixed: (interval, width) ->
        {@start, end} = interval
        @intervalLength = end - @start
        @width = width

We can put on axis ticks and labels, and also colour areas between them (but the coloring is not implemented yet).  They correspond to a set of time points.  Labels could correspond to time points or to time intervals between these points.

So we need to build a list of time points that correspond to the given `interval`.  We will put such code in a special function, `findPointList()`.

        pointList = @findPointList @start, end

Now, when we have found the list of time points, we need to construct a dictionary with graphical elements.  To transform time value into a horizontal coordinate we use the `timeToCoord()` function.  We start with ticks.  Each tick is a line.  The @options.tickLength parameter is a base length of a tick.  We set tick length from baseline downwards to `@options.tickLength`, and `@options.tickLength * @options.tickTailRatio` upwards.

        ticks = for timePoint in pointList
          {
            x1: @timeToCoord timePoint
            x2: @timeToCoord timePoint
            y1: -@options.tickLength * @options.tickTailRatio
            y2: @options.tickLength
          }

We also add axis (a horizontal line).  It spans the whole width of the given interval.

        axisLine = {
          x1: 0
          x2: @width
          y1: @options.axisLineOffset
          y2: @options.axisLineOffset
        }

Now we construct a list of text features, each has coordinates and string.

_Note_:  here we also need to improve formatting, now it's just a quick fix to display text.  Text should be formatted without problems on any display and resolution and shouldn't intersect ticks when it has reasonable font size.

To do it we first make a list of text labels assuming point label placement.

        textLabels = for timePoint in pointList
          {
            x: @timeToCoord timePoint
            y: @options.labelOffset
            text: @formatLabel timePoint, @options
          }

Then, if `options.labelPlacement` is equal to 'interval', we remove the last item and adjust horizontal coordinates of other items.

_Note_: one could think of better implementation here.  I tried to make it shorter and came to the current solution.

        if @options.labelPlacement is 'interval'
          for textLabel, i in textLabels when i isnt (textLabels.length-1)
            textLabel.x = (textLabel.x + textLabels[i+1].x) / 2
          textLabels.pop()

Now we combine all elements into one dictionary and return it;  we store ticks and other lines in `lines` element of the dictionary.

        features =
          lines: ticks.concat axisLine
          textLabels: textLabels

#### The `findPointList()` function ####

This function returns a list of points that are needed to be displayed for an interval.  The following arguments are necessary:
 * `start`:  when the interval starts, `Date` object.
 * `end`:  when the interval ends, `Date` object.

It returns a list of `Date` objects.

      findPointList: (start, end) ->

Since we could need to display labels between time points, we need to find time points inside the interval (non-inclusive) and one point on left and right side.  We can build the point list by finding the leftmost _edge time point_ which is strictly less than the `start` of the interval.  We move code that does that to the `findLeftTime()` function:

        timePoint = @findLeftTime start

Then, we populate the list in by incrementing points until we reach right end of the interval, using `findNextPoint()` function.  We move to that function code that gives next _edge time point_ for a supplied _edge time point_.

        pointList = [timePoint]
        until timePoint > end
          timePoint = @findNextPoint timePoint
          pointList.push timePoint

Then we return the list of time points:

        pointList

#### The `findLeftTime()` function ####

The `findLeftTime()` function calculates the rightmost _edge time point_ for current `options.intervalType` such that it is not greater than a given point of time.

Function arguments:
 * `start`:  a point of time, `Date` object.

It returns a `Date` object.

      findLeftTime: (start) ->

To calculate such value for years and months we just truncate them, while for days and weeks we will count from a fixed origin day near Epoch (Monday 5 January 1970), so that any day intervals are independent from underlying months and years.  That also means that in case of months the `options.intervalMultiplier` should be equal to 1, 2, 3, 4 or 6 to be displayed correctly.  To calculate number of days or weeks (reduced to 7 calculation for 7 days) from origin day we use binary subtracting, starting from huge multiplier equal to 1048576 (roughly 2800/11200 years), going down to base multiplier equal to 1.  For interval types smaller or equal than hours we use the `findNextPoint()` function by incrementing local origin (the interval values like years, months, and days are kept the same, while everything smaller is reset to 0).  This is done to avoid problems with daylight-saving and similar issues.  In `findNextPoint()` we make sure that edge points are consistent while using different values of `start` (for example on 02-00 before daylight-saving and 02-00 after daylight-saving on the same day both lead to the same next point if `options.intervalMultiplier` is larger than 1).

        leftTime = new Date start.getTime()
        switch @options.intervalType
          when 'year'
            newYear = start.getFullYear() -
              start.getFullYear() % @options.intervalMultiplier
            leftTime.setFullYear newYear, 0, 1
            leftTime.setHours 0, 0, 0, 0
          when 'month'
            newMonth = start.getMonth() -
              start.getMonth() % @options.intervalMultiplier
            leftTime.setMonth newMonth, 1
            leftTime.setHours 0, 0, 0, 0
          when 'week', 'day'
            leftTime.setFullYear 1970, 0, 5
            leftTime.setHours 0, 0, 0, 0
            intervalMultiplier = @options.intervalMultiplier
            if @options.intervalType is 'week'
              intervalMultiplier *= 7

Here it can happen that `start` is actually earlier than Epoch.  Then we decrease `leftTime` first:

            if start < leftTime
              delta = 1
              while start <= leftTime
                leftTime = new Date leftTime.getFullYear(),
                  leftTime.getMonth()
                  leftTime.getDate() - delta*intervalMultiplier
                  leftTime.getHours()
                  leftTime.getMinutes()
                  leftTime.getSeconds()
                  leftTime.getMilliseconds()
                delta *= 2

Now we move forwart until we find the right point:

            delta = 1048576
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
            nextTime = leftTime
            while nextTime < start
              nextTime = @findNextPoint leftTime
              leftTime = nextTime if nextTime <= start
          when 'minute'
            newMinutes = start.getMinutes() -
              start.getMinutes() % @options.intervalMultiplier
            leftTime.setMinutes newMinutes, 0, 0
          when 'second'
            leftTime.setSeconds 0, 0
            nextTime = leftTime
            while nextTime < start
              nextTime = @findNextPoint leftTime
              leftTime = nextTime if nextTime <= start
          when 'millisecond'
            newMilliseconds = start.getMilliseconds() -
              start.getMilliseconds() % @options.intervalMultiplier
            leftTime.setMilliseconds newMilliseconds
        leftTime

There is code repetition in the switch statement above.  One can think of a good way to improve this part of code.

#### The `findNextPoint()` function ####

This function calculates next _edge time point_ for current options assuming `timePoint` argument is _edge time point_.  We take care of daylight-saving time and leap seconds here, assuming that at most one hour/minute/second/millisecond is added or subtracted during leap or clock change.  Also we assume that leap or clock change is not happening at time with 0 value, that is something like 00 -> 23 is not happening.

Function arguments:
 * `timePoint`:  current edge time point, `Date` object.

It returns a `Date` object.

      findNextPoint: (timePoint) ->

The algorithm behind the function is simple:  for current `options.intervalType` it increments it by `options.intervalMultiplier` using `Date` methods.  Except for cases when we deal with hours and seconds, where we check if after incremental `options.intervalType` is divisible by `options.intervalMultiplier` (which should be the case).  If not, we adjust to the most suitable value, movinhg back or forward by one hour or second.

        nextTime = new Date timePoint.getTime()
        switch @options.intervalType
          when 'year'
            nextTime.setFullYear (timePoint.getFullYear() +
              @options.intervalMultiplier)
          when 'month'
            nextTime.setMonth (timePoint.getMonth() +
              @options.intervalMultiplier)
          when 'week'
            nextTime.setDate (timePoint.getDate() +
              7*@options.intervalMultiplier)
          when 'day'
            nextTime.setDate (timePoint.getDate() +
              @options.intervalMultiplier)
          when 'hour'
            nextTime.setUTCHours (timePoint.getUTCHours() +
              @options.intervalMultiplier)
            hours = nextTime.getHours()
            if hours % @options.intervalMultiplier isnt 0
              if (hours+1) % @options.intervalMultiplier is 0
                nextTime.setUTCHours (nextTime.getUTCHours() + 1)
              else
                nextTime.setUTCHours (nextTime.getUTCHours() - 1)
          when 'minute'
            nextTime.setMinutes (timePoint.getMinutes() +
              @options.intervalMultiplier)
          when 'second'
            nextTime.setUTCSeconds (timePoint.getUTCSeconds() +
              @options.intervalMultiplier)
            seconds = nextTime.getSeconds()
            if seconds % @options.intervalMultiplier isnt 0
              if (seconds+1) % @options.intervalMultiplier is 0
                nextTime.setUTCSeconds (nextTime.getUTCSeconds() + 1)
              else
                nextTime.setUTCSeconds (nextTime.getUTCSeconds() - 1)
          when 'millisecond'
            nextTime.setUTCMilliseconds (timePoint.getUTCMilliseconds() +
              @options.intervalMultiplier)
        nextTime

#### The `timeToCoord()` function ####

To get horizontal coordinate of time point we use `@intervalLength` that we stored in `formatFixed()`, which is equal to the number of milliseconds between `end` and `start` of the interval.  We use it to calculate pixel/time ratio, equal to `@width / @intervalLength`.

Function arguments:
 * `time`:  time point, `Date` object.

It returns a number between 0 and `@width`.

      timeToCoord: (time) ->
        timeFromStart = time - @start
        coordinate = timeFromStart * @width / @intervalLength

#### The `findNominalInterval()` function ####

This function returns the approximate length of interval between two consecutive edge time points for a given values of `intervalType` and `intervalMultiplier`.

Return value is in milliseconds.

      @findNominalInterval: (intervalType, intervalMultiplier) ->
        switch intervalType
          when 'year'
            millisecondsInYear = 1000*60*60*24*365
            intervalMultiplier * millisecondsInYear
          when 'month'
            millisecondsInMonth = 1000*60*60*24*30
            intervalMultiplier * millisecondsInMonth
          when 'week'
            millisecondsInWeek = 1000*60*60*24*7
            intervalMultiplier * millisecondsInWeek
          when 'day'
            millisecondsInDay = 1000*60*60*24
            intervalMultiplier * millisecondsInDay
          when 'hour'
            millisecondsInHour = 1000*60*60
            intervalMultiplier * millisecondsInHour
          when 'minute'
            millisecondsInMinute = 1000*60
            intervalMultiplier * millisecondsInMinute
          when 'second'
            intervalMultiplier * 1000
          when 'millisecond'
            intervalMultiplier

__Note__:  should we optimize it here (both precalculate numbers and deduplicate code)?

#### The `formatLabel` function ####

This function returns text representation of date.

      formatLabel: (timePoint, options) ->
        switch options.intervalType
          when 'year'
            if (options.intervalMultiplier > 1 and
                options.labelPlacement is 'interval')
              nextTimePoint = @findNextPoint timePoint
              nextTimePoint.setFullYear(nextTimePoint.getFullYear() - 1)
              timePoint.getFullYear().toString() +
                '–' + nextTimePoint.getFullYear()
            else
              timePoint.getFullYear().toString()
          when 'month'
            if (options.intervalMultiplier > 1 and
                options.labelPlacement is 'interval')
              nextTimePoint = @findNextPoint timePoint
              nextTimePoint.setMonth(nextTimePoint.getMonth() - 1)
              timePoint.getMonth().toString() +
                '–' + nextTimePoint.getMonth().toString()
            else
              timePoint.getMonth().toString()
          when 'week'
            if options.labelPlacement is 'interval'
              nextTimePoint = @findNextPoint timePoint
              nextTimePoint.setDate(nextTimePoint.getDate() - 1)
              timePoint.getDate().toString() +
                '–' + nextTimePoint.getDate().toString()
            else
              timePoint.getDate().toString()
          when 'day'
            if (options.intervalMultiplier > 1 and
                options.labelPlacement is 'interval')
              nextTimePoint = @findNextPoint timePoint
              nextTimePoint.setDate(nextTimePoint.getDate() - 1)
              timePoint.getDate().toString() +
                '–' + nextTimePoint.getDate().toString()
            else
              timePoint.getDate().toString()
          when 'hour'
            if (options.intervalMultiplier > 1 and
                options.labelPlacement is 'interval')
              nextTimePoint = @findNextPoint timePoint
              nextTimePoint.setHours(nextTimePoint.getHours())
              timePoint.getHours().toString() +
                '–' + nextTimePoint.getHours().toString()
            else
              timePoint.getHours().toString()
          when 'minute'
            if (options.intervalMultiplier > 1 and
                options.labelPlacement is 'interval')
              nextTimePoint = @findNextPoint timePoint
              nextTimePoint.setMinutes(nextTimePoint.getMinutes())
              timePoint.getMinutes().toString() +
                '–' + nextTimePoint.getMinutes().toString()
            else
              timePoint.getMinutes().toString()
          when 'second'
            if (options.intervalMultiplier > 1 and
                options.labelPlacement is 'interval')
              nextTimePoint = @findNextPoint timePoint
              nextTimePoint.setSeconds(nextTimePoint.getSeconds())
              timePoint.getSeconds().toString() +
                '–' + nextTimePoint.getSeconds().toString()
            else
              timePoint.getSeconds().toString()
          when 'millisecond'
            if (options.intervalMultiplier > 1 and
                options.labelPlacement is 'interval')
              nextTimePoint = @findNextPoint timePoint
              nextTimePoint.setMilliseconds(nextTimePoint.getMilliseconds())
              ".#{ timePoint.getMilliseconds() }–.#{ nextTimePoint.getMilliseconds() }"
            else
              ".#{ timePoint.getMilliseconds() }"

#### The `@intervalsProgression` property ####

This property defines intervals that are could be used for formatting of time axis.  It is an array of objects, each of objects has two keys:  'type' with value of `intervalType` and 'multipliers' with array of values for `intervalMultiplier`.

      @intervalsProgression: [
        {type: 'millisecond', multipliers: [1, 5, 10, 50, 100, 500]}
        {type: 'second', multipliers: [1, 5, 15, 30]}
        {type: 'minute', multipliers: [1, 5, 15, 30]}
        {type: 'hour', multipliers: [1, 3, 6, 12]}
        {type: 'day', multipliers: [1]}
        {type: 'week', multipliers: [1]}
        {type: 'month', multipliers: [1, 3, 6]}
        {type: 'year', multipliers: [1, 5, 10, 50, 100, 500, 1000, 5000, 10000
          50000, 100000, 1000000, 10000000, 100000000]}
      ]

### The `TimeAxisRenderer` class ####

The `TimeAxisRenderer` class currently renders only to html canvas.

    class TimeAxisRenderer

#### The `TimeAxisRenderer` constructor ####

      constructor: () ->

#### The `renderToCanvas()` function ####

This function renders formatted time axis to html canvas.
 * `axisData` is formatted data (that we get by calling any of the `format...()` functions of the `TimeAxisMaker` class)
 * `canvas` is an html canvas object on which axis is drawn
 * `left` and `top` are x- and y-coordinates of the canvas that correspond to the (0, 0) point of the axis viewport

The code:

      renderToCanvas: (axisData, canvas, left, top) ->

In the beginning we do just regular initialization of canvas graphical context and its properties.  We also wrap our drawing code into `save()` and `restore()` to not alter context properties globally.

        context = canvas.getContext '2d'
        context.save()
        context.strokeStyle = '#000000'
        context.fillStyle = '#000000'
        context.lineWidth = 1
        context.font = 'normal 12px sans-serif'
        context.textAlign = 'center'
        context.textBaseline = 'top'

Instead of writing the same code again when we need canvas coordinates we define an additional nested function `translateCoord()` that turns logical corrdinates into canvas coordinates.  To all line drawing functions we pass coordinates altered by `roundForCanvas()` function, which rounds values in such a way that lines are more sharp.  We include `roundFlag` boolean option to the `translateCoord` function to make rounding of coordinates optional there.

        translateCoord = (coordX, coordY, roundFlag = true) =>
          newX = left + coordX
          newY = top + coordY
          if roundFlag
            newX = @roundForCanvas newX
            newY = @roundForCanvas newY
          newCoord = [newX, newY]

        context.beginPath()
        for line in axisData.lines
          [x1, y1] = translateCoord(line.x1, line.y1)
          [x2, y2] = translateCoord(line.x2, line.y2)
          context.moveTo x1, y1
          context.lineTo x2, y2
        context.stroke()

        for textLabel in axisData.textLabels
          [x, y] = translateCoord(textLabel.x, textLabel.y, false)
          context.fillText textLabel.text, x, y

        context.restore()

#### The `roundForCanvas()` function ####

This function may be used to avoud aliasing of lines, especially on low-resolution displays.  It rounds coordinate to middle-pixel values, which are .5 in case of html canvas.

      roundForCanvas: (coord) ->
        0.5 + Math.round(coord-0.5)

### Node module exports

Both `TimeAxisMaker` and `TimeAxisRenderer` are exported.

We temporarily disable it.

    #module.exports =
      #TimeAxisMaker: TimeAxisMaker
      #TimeAxisRenderer: TimeAxisRenderer

Library tests
-------------

------------------------------------------------------------

Examples
--------

The following small example is supposed to work together with an html-file that contains a canvas element with `id` equal to 'timeline'.

Time axis is displayed in that canvas;  it could be dragged using mouse and zoomed using mouse wheel.

### The source code ###

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
      timeAxisMaker = new TimeAxisMaker
        tickLength: 25
        intervalType: 'day'
        labelPlacement: 'interval'
        intervalMultiplier: 1
        labelOffset: 29
      start = new Date('2015-06-15T00:00:00')
      end = new Date('2015-07-13T15:23:49')
      timeAxisRedrerer = new TimeAxisRenderer()

Code that draws builds and draws axis is also moved in a function:

      makeAxis = ->
        axisData = timeAxisMaker.formatAutomatic {start, end}, canvas.width, 15
        timeAxisRedrerer.renderToCanvas axisData, canvas, 0, 15

Initial drawing:

      do makeAxis

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
          do makeAxis

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
          do makeAxis

We run the `makeDemo` function when page loads.

__TODO__:  we need to put example in another file.

    window.onload = makeDemo

------------------------------------------------------------

Information
-----------

### Authors ###
Eugene Petkevich, https://github.com/nasedil/

### License ###
TODO Decide on license.

### Version history ###
Still in alpha.

Notes
-----

### Dictionary ###

The following terms are routinely used in this file:
 * _edge time point_:  a point of time that is usually displayed on time axis using tick and/or label;  usually the right part of time is all zeroed (like 0 seconds; 0 minutes and seconds; 0 hours, minutes and seconds), and the rightmost non-zero value is a round number or is a mid-point (or several thirds, fourth, fifth, etc) of a time interval (for example 5 years; 3, or 6, or 12 hours; 30 minutes), or just an integer number.  The typical progression of edge time points would be:  00:05:00, 00:10:00, 00:15:00, 00:20:00, 00:25:00, ...

### Frequently Asked Questions ###
Want to ask a question?  Write to [Eugene](https://github.com/nasedil/)!

### References
No references so far.

### Notes related to only this file ###

Several ideas:
 * What if instead of calculating formatting from scratch each time, change it from current?

### Notes that should be moved away at some point ###

These notes are currently a draft of coding style, tricks and ideas that could be used in every CoffeeScript file.

Important notes:
 * Between a bullet list and code block there should be at lest 2 empty lines, otherwise code is not formatted correctly in Github.  However, it compiles without problem and works as it should.  This is probably a Github's bug. __Update__:  it seems that it doesn't work at all in github, something should be between a bullet list and a code block, otherwise github does not show code as code.  I will send a question to support@github.com
 * Use 60 dashes to include a horizontal line.  That makes horizontal line easily viewable in an editor too.
 * Limit line to 79 characters, at least code (text could be soft-wrapped).  That improves readability, even though screens are large these times.  Also it makes possible to view several documents on one screen.
