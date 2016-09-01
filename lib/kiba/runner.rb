require 'parallel'
require 'securerandom'

module Kiba
  module Runner
    def run(control)
      # instantiate early so that error are raised before any processing occurs
      pre_processes = to_instances(control.pre_processes, true, false)
      pre_processes.each(&:call)

      sources = to_instances(control.sources)
      destinations = to_instances(control.destinations)
      transforms = to_instances(control.transforms, true)
      process_rows(sources, transforms, destinations)
      destinations.each(&:close)

      post_processes = to_instances(control.post_processes, true, false)
      post_processes.each(&:call)
    end

    def process_rows(sources, transforms, destinations)
      sources.each do |source|
        puts "Processing source #{source.class.name}"
        counter = Kiba::Counter.new(SecureRandom.uuid, 0)
        counter.report :current
        timer  = (ENV['KIBA_TIMER'] || 'true') == 'true'
        timing = (ENV['KIBA_TIMING'] || 2).to_i
        # timer_thread = Thread.new do
          if timer
            Kiba.timers.now_and_every(timing) { counter.report :current }
            loop { Kiba.timers.wait }
          end
        # end
        pop    = ->() { source.pop || Parallel::Stop }
        start  = ->(_, _) { counter.increment! }
        Parallel.each(pop, in_processes: processes_count, start: start) do |row|
          # Parallel.each(pop, in_processes: processes_count) do |row|
          transforms.each do |transform|
            # TODO: avoid the case completely by e.g. subclassing Proc
            # and aliasing `process` to `call`. Benchmark needed first though.
            if transform.is_a?(Proc)
              row = transform.call(row)
            else
              row = transform.process(row)
            end
            break unless row
          end
          next unless row
          destinations.each do |destination|
            destination.write(row)
          end
        end
        source.close
        # timer_thread.exit
        counter.report :current
      end
    end

    # not using keyword args because JRuby defaults to 1.9 syntax currently
    def to_instances(definitions, allow_block = false, allow_class = true)
      definitions.map do |d|
        case d
        when Proc
          fail 'Block form is not allowed here' unless allow_block
          d
        else
          fail 'Class form is not allowed here' unless allow_class
          d[:klass].new(*d[:args])
        end
      end
    end

    def processes_count
      (ENV['KIBA_PROCESSES'] || 0).to_i
    end
  end
end
