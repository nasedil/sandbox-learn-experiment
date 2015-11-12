#!/bin/bash

# This is a continuous bulid script for the timeline-scale package
# Have a look at https://github.com/nasedil/timeline-scale
# This code is licensed under the terms of the MIT license.

coffee -o build/lib/ -cw src/timeline-scale-library.litcoffee &
coffee -o build/demo/ -cw src/timeline-scale-example.litcoffee &
jade -o build/demo/ -Pw src/demo.jade &
