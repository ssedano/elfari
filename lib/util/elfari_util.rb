class ElFariUtil
    def self.extract_seek_time(expr = "")
        seconds = 0
        matcher = /(\s*(\d+)\s?[h])?[:]?(\s*(\d+)\s?[m])?[:]?(\s*(\d+)\s?[s])?/.match(expr)
        hours = matcher.values_at(2)
        minutes = matcher.values_at(4)
        seconds_expr = matcher.values_at(6)
        seconds += hours.first.to_i * 3600 unless hours.nil?
        seconds += minutes.first.to_i * 60 unless minutes.nil?
        seconds += seconds_expr.first.to_i unless seconds_expr.nil?
        return seconds
    end
end 
