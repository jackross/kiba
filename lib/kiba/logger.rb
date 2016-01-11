module Kiba
  module Logger
    module_function

    def at
      I18n.l Time.now.utc, format: :exact_at
    rescue
      Time.now.utc.strftime 'at %Y-%m-%d %H:%M:%S:%L'
    end

    def log(msg)
      puts "#{msg.ljust(80)} #{at}"
    end
  end
end
