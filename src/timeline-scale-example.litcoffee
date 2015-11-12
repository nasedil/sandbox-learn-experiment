Timeline Scale Library -- a simple example
==========================================

Abstract
--------

This file contains an example that uses timeline scale visualization in literate CoffeeScript.  Description is followed by source code with explanations.  The example uses [timeline-scale-library](src/timeline-scale-library.litcoffee).  For more information about this library, have a look at the [readme file](../README.md).

The project is hosted [here](https://github.com/nasedil/timeline-scale).  This project is licensed under the terms of the MIT license.

This file is written in Literate [CoffeeScript](http://coffeescript.org/#literate), using [Github Flavored Markdown](https://help.github.com/articles/github-flavored-markdown/).

Table of Contents
-----------------

 1. [Example implementation](#example-implementation)
 2. [Information](#information)
    1. [Authors](#authors)
    2. [License](#license)
    3. [Version history](#version-history)
 3. [Notes](#notes)

------------------------------------------------------------

Example implementation
----------------------

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
      timeAxisMaker = new TimelineScale.TimeAxisMaker({})
      start = new Date('2015-06-15T00:00:00')
      end = new Date('2015-07-13T15:23:49')
      timeAxisRedrerer = new TimelineScale.TimeAxisRenderer()

Code that draws builds and draws axis is also moved in a function:

      makeAxis = ->
        axisData = timeAxisMaker.formatMultiLaneAxis {start, end}, canvas.width
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

    window.onload = makeDemo

------------------------------------------------------------

Information
-----------

### Authors ###
Eugene Petkevich, https://github.com/nasedil/

### License ###
This code is licensed under the terms of the MIT license.

### Technical information ###
This file is written in Literate [CoffeeScript](http://coffeescript.org/#literate), using [Github Flavored Markdown](https://help.github.com/articles/github-flavored-markdown/).  You need to compile to get javascript code, and it is best highlighted when viewed in Github.

### Frequently Asked Questions ###
Want to ask a question?  Write to [Eugene](https://github.com/nasedil/)!

### Version history ###
Still in alpha.

Notes
-----

### References
No references so far.
