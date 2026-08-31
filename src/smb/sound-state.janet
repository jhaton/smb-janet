(def queue-addresses @[0x00fa 0x00fb 0x00fc 0x00fd 0x00fe 0x00ff])
(def buffer-addresses @[0x07b2 0x00f4 0x07b1 0x00f3 0x00f2 0x00f1])
(def queue-count (length queue-addresses))
(def max-events (* queue-count 8))

(defn make-state
  "Create sound-engine presentation state with no Raylib or gameplay ownership."
  []
  @{:queues (buffer/new-filled queue-count)
    :buffers (buffer/new-filled queue-count)
    :event-queues (buffer/new-filled max-events)
    :event-bits (buffer/new-filled max-events)
    :event-count 0})

(defn update!
  "Observe sound queues and buffers without mutating gameplay RAM."
  [state ram]
  (put state :event-count 0)
  (loop [queue :range [0 queue-count]]
    (def previous (get (state :queues) queue))
    (def current (get ram (get queue-addresses queue)))
    (def asserted (band current (bxor previous 0xff)))
    (loop [bit :range [0 8]]
      (when (not= (band asserted (blshift 1 bit)) 0)
        (def event (state :event-count))
        (when (>= event max-events)
          (error "sound event buffer overflow"))
        (put (state :event-queues) event queue)
        (put (state :event-bits) event bit)
        (put state :event-count (inc event))))
    (put (state :queues) queue current)
    (put (state :buffers) queue (get ram (get buffer-addresses queue))))
  state)
