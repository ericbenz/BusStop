# BusStop
Final project for [COSI 136a Automated Speech Recognition](http://www.cs.brandeis.edu/~cs136a/) (Prof. Marie Meteer). Essentially looking to develop an app that will allow us to roughly build on the functionalities already within 'NextBus', but enhance it with an ASR system. All this will be tailored specifically to MBTA bus routes using the [MBTA Developer Portal](http://realtime.mbta.com/portal).

### Group Members
All students below are Brandeis Computational Linguistics MA 2016s
- Eric Benzschawel
- Adam Berger
- Suzanne Blackley
- Swini Garimella

### To Do List
- add destination pin at destination
- figure out how to get bus routing information
- look into geographical coverage for transit routing
- build out new wit intents
- add conditional logic for each intent
- train RouteToLocation intent (4x10 instances on mobile devices)

### User Testing
- Verify userLocation label updates as user moves
- Verify map displays routing directions to reasonable locations near the user

### Done
- map zooms to user location
- map updates as user moves
- wit.ai integrated
- RouteToLocation intent integrated
- Directions generated with extracted ASR
- Map polyline overlay working for directions
- Figure out how to get app on phones for testing

### Blockers
Eric - iPhone beta OS not compatible with current version of Xcode, which is complicating putting app on device for user testing