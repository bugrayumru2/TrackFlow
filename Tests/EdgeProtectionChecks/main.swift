import Foundation

var typing = TypingGuard()
assert(!typing.isLocked(at: 10))
typing.recordKeyDown(at: 10)
assert(typing.isLocked(at: 10))
assert(typing.isLocked(at: 10.799))
assert(!typing.isLocked(at: 10.801))
typing.recordKeyDown(at: 10.7)
assert(typing.isLocked(at: 11.4), "Every keystroke extends the cooldown")
assert(!typing.isLocked(at: 11.501))

for edge in [EdgeVolumeGesture.Edge.left, .right] {
    let x = edge == .left ? 0.06 : 0.94
    var gesture = EdgeVolumeGesture(edge: edge)
    assert(gesture.process(id: 1, x: x, y: 0.5) == nil, "Touch alone must not change a level")
    assert(gesture.process(id: 1, x: x, y: 0.51) == nil)
    assert(gesture.process(id: 1, x: x, y: 0.49) == nil, "Jitter must not accumulate")
    assert(gesture.process(id: 1, x: x, y: 0.54) == 54)
    assert(gesture.isArmed)
    assert(gesture.process(id: 1, x: x, y: 0) == 0)
    assert(gesture.process(id: 1, x: x, y: 0.5) == 50)
    assert(gesture.process(id: 1, x: x, y: 1) == 100)
    gesture.reset() // Also called immediately by the keyboard activity callback.
    assert(!gesture.isArmed)
    assert(gesture.process(id: 1, x: x, y: 1) == nil, "A keyboard reset must require a new swipe")
    assert(gesture.process(id: 1, x: x, y: 0.99) == nil)
    assert(gesture.process(id: 1, x: x, y: 0.95) == 95)
    assert(gesture.process(id: 1, x: 0.5, y: 0.5) == nil, "Leaving an edge disarms it")
    assert(gesture.process(id: 1, x: x, y: 0.5) == nil)
    assert(gesture.process(id: 2, x: x, y: 0.6) == nil, "New finger must not inherit activation")
    assert(!gesture.isArmed)
    assert(gesture.process(id: 2, x: x, y: 0.6) == nil)
    assert(gesture.process(id: 2, x: x, y: 0.55) == 55)
    assert(gesture.process(id: 2, x: x, y: .nan) == nil)
    assert(!gesture.isArmed)
}
print("Typing cooldown, repeated typing, deliberate activation, jitter, reset and 0/50/100 checks passed.")
