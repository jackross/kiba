module Kiba
  class Counter
    attr_reader :store, :key, :started_at

    def initialize(key = :default, initial_value = 0)
      @started_at = Time.now
      @key = [redis_key_style(self.class), redis_key_style(key)].join(':')
      @store = Kiba.redis
      self.count = initial_value
    end

    def count
      store.get key
    end

    def count=(new_count)
      store.set key, new_count
    end

    def increment!
      store.pipelined { store.incr(key) }
    end

    def report(n)
      c = count.to_i
      f = format('%7d', c)
      if n == :current
        Kiba::Logger.log "Processed #{f} rows (#{formatted_per_second(c)})"
      else
        Kiba::Logger.log "Processing row #{f}" if count % n == 0
      end
    end

    def per_second(n)
      n / (Time.now - started_at)
    end

    def formatted_per_second(c)
      "#{format('%10.5f', per_second(c))} rows / second"
    end

    private

    def redis_key_style(klass)
      klass.name.underscore.gsub(%r{\/}, ':').tr(/_/, '-')
    end
  end
end
