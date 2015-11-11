#!/bin/bash

coffee -o build/lib/ -cw src/timeline-scale-library.litcoffee
coffee -o build/demo/ -cw src/timeline-scale-example.litcoffee
jade -o build/demo/ -Pw src/demo.jade
