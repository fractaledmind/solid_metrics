module SolidMetrics
  # Patch `ActiveSupport::Subscriber` to setup monotonic subscriptions.
  class Subscriber < ActiveSupport::Subscriber
    private

      def add_event_subscriber(event) # :doc:
        return if invalid_event?(event)

        pattern = prepare_pattern(event)

        # Don't add multiple subscribers (e.g. if methods are redefined).
        return if pattern_subscribed?(pattern)

        subscriber.patterns[pattern] = notifier.subscribe(pattern, subscriber, monotonic: true)
      end
  end
end
