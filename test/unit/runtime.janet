(import spork/test)
(import ../../src/smb/runtime)
(import ../../src/smb/movement)

(test/start-suite "hot redefinition preserves running state")

(def app (runtime/make-runtime))
(runtime/reload-step! app)
(def stable-world (app :world))
(def stable-ram (stable-world :ram))

(loop [i :range [0 90]]
  (runtime/tick! app))

(def frame-before (stable-world :frame))
(def x-before (get stable-ram movement/x-position-base))
(def old-step (app :step))
(put stable-ram 0x700 0xa5)
(runtime/reload-step! app)

(test/assert (= stable-world (app :world))
             "reload must retain the world table")
(test/assert (= stable-ram ((app :world) :ram))
             "reload must retain the gameplay RAM buffer")
(test/assert (not= old-step (app :step))
             "reload must install a newly compiled frame function")
(test/assert (= (app :reload-generation) 2)
             "reload generation must advance")
(test/assert (= (app :last-reload-frame) frame-before)
             "reload must occur at a frame boundary")
(test/assert (= ((app :world) :frame) frame-before)
             "reload must not advance or reset simulation time")
(test/assert (= (get stable-ram 0x700) 0xa5)
             "unrelated gameplay RAM must survive reload")

(runtime/tick! app)
(test/assert (= ((app :world) :frame) (inc frame-before))
             "new frame function must continue from existing time")
(test/assert (not= (get stable-ram movement/x-position-base) x-before)
             "new frame function must continue existing motion")
(test/assert (= (get stable-ram 0x700) 0xa5)
             "running state must remain intact after the redefined step executes")

(test/end-suite)
