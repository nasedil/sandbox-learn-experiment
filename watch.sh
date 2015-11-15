#!/bin/bash

# This is a continuous bulid script for the timeline-scale package
# Have a look at https://github.com/nasedil/timeline-scale
# This code is licensed under the terms of the MIT license.

./node_modules/.bin/coffee -o build/lib/ -cw src/timeline-scale-library.litcoffee &
./node_modules/.bin/coffee -o build/demo/ -cw src/timeline-scale-example.litcoffee &
./node_modules/.bin/jade -o build/demo/ -Pw src/demo.jade &
