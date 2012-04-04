Class ElfariUtil
    def self.extract_seek_time(expr = "")
        seconds = 0
        hours = /(\+d)h/.match(expr)
        minutes = /(\+d)m/.match(expr)
        seconds_expr = /(\d+)s/.match(expr)
        seconds += hours * 3600 unless hours.nil?
        seconds += minutes * 60 unless minutes.nil?
        seconds += seconds_expr unless seconds_expr.nil?
        
        return seconds
    end
    
end
