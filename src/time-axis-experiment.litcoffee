Timeline axis in CoffeeScript
=============================

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

 1. At least show one time label that corresponds to the provided time interval.

### Unit test cases

To be done:
 * Labels should not intersect with each other

Development concerns
--------------------

### Readability

The following things should be thought of before making a final version:
 * DPI should be taken into account.
 * Every element should be separated from others.
    * Visual elements should not intersect with each other.
    * Visual elements such as labels and ticks should be at some good distance to each other.
 * It is a good idea to alternate colors of intervals.
    * Use two colors.
    * They should differ for visually impaired.
    * And should be suitable for grey-color display.
    * Thus, they should differ in brightness at least.

### Portability

To make it more flexible to render (to canvas, svg, vega, anything else), we should have an intermediate object as output of axis formatting, which could be rendered after withe a chosen rendeder.

Library functions
-----------------

A function that formats time axis into an intermediate format.  It has three parameters, _interval_ (a dictionary with _start_ and _end_ values) and corresponding to that interval _viewport_, and formatting _options_.

    formatTimeAxis = (interval, viewport, options) ->
      
