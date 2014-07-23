module Yelp
  module Error
    # Validates Yelp API responses.  This class shouldn't be used directly, but
    # should be accessed through the Yelp::Error.check_for_error interface.
    # @see check_for_error
    class ResponseValidator

      # If the request is not successful, raise an appropriate Yelp::Error
      # exception with the error text from the request response.
      # @param response from the Yelp API
      def validate(response)
        return if successful_response?(response)
        raise error_from_response(response)
      end

      private

      def successful_response?(response)
        # Check if the status is in the range of non-error status codes
        (200..399).include?(response.status)
      end

      # Create an initialized exception from the response
      # @return [Yelp::Error::Base] exception corresponding to API error
      def error_from_response(response)
        body = JSON.parse(response.body)
        klass = error_classes[body['error']['id']]
        message = body['error'].map { |k, v| "#{k}: #{v}" }.join(', ') +
          "\nurl: #{response.env[:url].to_s}"
        ex = klass.new(message)
        ex.response = response
        ex.error = body['error']
        ex.url = response.env[:url].to_s
        ex
      end

      # Maps from API Error id's to Yelp::Error exception classes.
      def error_classes
        @@error_classes ||= Hash.new do |hash, key|
          class_name = key.split('_').map(&:capitalize).join('').gsub('Oauth', 'OAuth')
          hash[key] = Yelp::Error.const_get(class_name)
        end
      end
    end

    # Check the response for errors, raising an appropriate exception if
    # necessary
    # @param (see ResponseValidator#validate)
    def self.check_for_error(response)
      @response_validator ||= ResponseValidator.new
      @response_validator.validate(response)
    end

    class Base < StandardError
      attr_accessor :response, :error, :url
    end

    class AlreadyConfigured < Base
      def initialize(msg = 'Gem cannot be reconfigured.  Initialize a new ' +
          'instance of Yelp::Client.')
        super
      end
    end

    class MissingAPIKeys < Base
      def initialize(msg = "You're missing an API key")
        super
      end
    end

    class MissingLatLng < Base
      def initialize(msg = 'Missing required latitude or longitude parameters')
        super
      end
    end

    class BoundingBoxNotComplete < Base
      def initialize(msg = 'Missing required values for bounding box')
        super
      end
    end

    class InternalError           < Base; end
    class ExceededRequests        < Base; end
    class MissingParameter        < Base; end
    class InvalidParameter        < Base; end
    class InvalidSignature        < Base; end
    class InvalidOAuthCredentials < Base; end
    class InvalidOAuthUser        < Base; end
    class AccountUnconfirmed      < Base; end
    class UnavailableForLocation  < Base; end
    class AreaTooLarge            < Base; end
    class MultipleLocations       < Base; end
    class BusinessUnavailable     < Base; end
  end
end
