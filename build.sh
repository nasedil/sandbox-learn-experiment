#!/bin/bash

coffee -o build/lib/ -c src/timeline-scale-library.litcoffee
coffee -o build/demo/ -c src/timeline-scale-example.litcoffee
jade -o build/demo/ -P src/demo.jade
