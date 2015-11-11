
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
      timeAxisMaker = new TimeAxisMaker({})
      start = new Date('2015-06-15T00:00:00')
      end = new Date('2015-07-13T15:23:49')
      timeAxisRedrerer = new TimeAxisRenderer()

Code that draws builds and draws axis is also moved in a function:

      makeAxis = ->
        axisData = timeAxisMaker.formatMultiLaneAxis {start, end}, canvas.width, 15
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
