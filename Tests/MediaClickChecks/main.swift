import Foundation
import AppKit

assert(MediaClickRouter.action(x: 0.2, y: 0.95) == .previous)
assert(MediaClickRouter.action(x: 0.5, y: 0.95) == .playPause)
assert(MediaClickRouter.action(x: 0.8, y: 0.95) == .next)
for x in [0.0, 0.12, 0.88, 1.0] {
    assert(MediaClickRouter.action(x: x, y: 0.99) == nil, "Corners belong to volume/brightness")
}
assert(MediaClickRouter.action(x: 0.5, y: 0.87) == nil)
assert(MediaClickRouter.action(x: .nan, y: 0.95) == nil)
assert(MediaClickRouter.action(x: 0.5, y: .infinity) == nil)
var router = MediaClickRouter()
router.update(x: 0.5, y: 0.95, at: 10)
assert(router.mouseDown(pressure: 0, at: 10.01) == nil, "Tap must not trigger")
assert(!router.mouseUp())
assert(router.mouseDown(pressure: 1, at: 10.02) == .playPause)
assert(router.consumingClick)
assert(router.mouseDown(pressure: 1, at: 10.03) == nil, "One command per press")
router.clearCandidate()
assert(router.mouseUp(), "Release must still be consumed after disabling")
assert(!router.mouseUp())
router.update(x: 0.2, y: 0.95, at: 11)
assert(router.mouseDown(pressure: 1, at: 11.2) == nil, "Stale touch must not trigger")
router.update(x: nil, y: nil, at: 12)
assert(router.mouseDown(pressure: 1, at: 12) == nil, "Multiple/no fingers must not trigger")
for edge in [EdgeVolumeGesture.Edge.left, .right] {
    var gesture = EdgeVolumeGesture(edge: edge)
    let x = edge == .left ? 0.06 : 0.94
    assert(gesture.process(id: 1, x: x, y: 0) == nil)
    assert(gesture.process(id: 1, x: x, y: 0.04) == 4)
    for (y, expected) in [(0.0, 0), (0.5, 50), (1.0, 100)] {
        assert(gesture.process(id: 1, x: x, y: y) == expected)
    }
}
for action in [SpotifyAction.previous, .playPause, .next] {
    let script = NSAppleScript(source: "tell application id \"com.spotify.client\" to \(action.command)")!
    var error: NSDictionary?
    assert(script.compileAndReturnError(&error), "Spotify dictionary rejected command")
}
print("Media routing, physical-click gating, release handling, edge regression, Spotify script compilation: passed.")
