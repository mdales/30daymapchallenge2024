# 30daymapschallenge: Day 1 & Day 2

## Day 1 - Points

Day 1 of [30daymapschallenge](https://30daymapchallenge.com), the theme is points. I [already had some code](https://github.com/mdales/claudius-examples/blob/main/day1/bin/main.ml) from day 1 of [Genuary](https://genuary.art), which pretty much started with the same prompt, that made a sphere of points, so I combined that with loading data from a [GeoJSON](https://en.wikipedia.org/wiki/GeoJSON) file, and plotting point data in the GeoJSON on the rotating sphere.

For example, here it is showing [a dataset of lighthouse locations](https://www.kaggle.com/datasets/bcruise/lighthouse-locations):

![An animated gif showing a rotating globe made of just points along the coastlines of most countries](example1.gif)

## Day 2 - Lines

For Day 2 the theme is lines, so I abstracted out the GeoJSON code to make it easier to build up, and added line support, and now am displaying [some data on global shipping lanes](https://zenodo.org/records/6361813). That said, it is turning into a tool that I can just throw a GeoJSON file at and have it render on a spinning globe.

![An animated gif showing a rotating globe made of just lines that cross the oceans between missing countries](example2.gif)
