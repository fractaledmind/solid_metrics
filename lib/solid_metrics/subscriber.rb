module SolidMetrics
  # Patch `ActiveSupport::Subscriber`
  class Subscriber < ActiveSupport::Subscriber
    class << self
      private

        # Patch `ActiveSupport::Subscriber#add_event_subscriber` to setup monotonic subscriptions.
        def add_event_subscriber(event) # :doc:
          return if invalid_event?(event)

          pattern = prepare_pattern(event)

          # Don't add multiple subscribers (e.g. if methods are redefined).
          return if pattern_subscribed?(pattern)

          subscriber.patterns[pattern] = notifier.monotonic_subscribe(pattern, subscriber)
        end
    end
  end
end
