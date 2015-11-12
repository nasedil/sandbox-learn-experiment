#!/bin/bash

# This is a bulid script for the timeline-scale package
# Have a look at https://github.com/nasedil/timeline-scale
# This code is licensed under the terms of the MIT license.

coffee -o build/lib/ -c src/timeline-scale-library.litcoffee
coffee -o build/demo/ -c src/timeline-scale-example.litcoffee
jade -o build/demo/ -P src/demo.jade
