require "mengpaneel/strategy/base"
require "mengpaneel/strategy/server_side"
require "json"

module Mengpaneel
  module Strategy
    class AsyncServerSide < Base
      def run
        return false unless self.class.async?
        return true if all_calls[:tracking].blank?

        Worker.perform_later(all_calls.to_json, controller.try(:request).try(:remote_ip))

        true
      end

      private
        def self.async?
          defined?(::ActiveJob)
        end

      if async?
        class Worker < ::ActiveJob::Base
          queue_as :default

          def perform(all_calls, remote_ip = nil)
            all_calls = JSON.parse(all_calls)

            Strategy::ServerSide.new(all_calls, nil, remote_ip).run
          end
        end
      end
    end
  end
end