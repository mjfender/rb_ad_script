require 'csv'
require 'date'

def parse_csv
  all_categories ||= {}

  # line 8 imports the raw performance_data.csv one row at a time, converting values into hashes
  CSV.foreach("./performance_data.csv",  {:headers => true, :header_converters => :symbol, :converters => :all }) do |row|
    bucket_category(row.to_hash, all_categories)
    #for each row of data, add its metrics to the category aggregator object
  end

  total_values = get_total_values(all_categories)
  # find the total values for each column header

  add_calculated_fields(all_categories, total_values)
  # add the calculated fields (click rate, conv rate, relative performance) to each of the category rows

  new_values = sorter(all_categories)
  # sort the categories in descending order, highest relative_perfomance first

  filename = "perf_by_category_#{DateTime.now.strftime('%s')}.csv"
  # create csv with name based on timestamp

  CSV.open(filename, "wb") do |csv|
    csv << ['Category Name', 'Impressions', 'Viewed Impressions', 'Clicks', 'Conversions', 'Click Rate', 'Conversion Rate', 'Relative Performance']

    new_values.to_a.each do |elem|
      row = []
      row << elem[0]
      row << elem[1].map do |key, value|
        value
        end
      csv << row.flatten
    end

    # create a summary row for dataset totals and averages
    final_row = ["Totals"]
    final_row << total_values[:imps]
    final_row << total_values[:viewed_imps]
    final_row << total_values[:clicks]
    final_row << total_values[:convs]
    final_row << ( total_values[:clicks].to_f / total_values[:imps].to_f ) #clickrate
    final_row << ( total_values[:convs].to_f / total_values[:imps].to_f ) #convrate
    final_row << "NA"
    csv << final_row
  end

  # report success back to command line
  puts "'Performance Data by Category' report complete. Results are in #{filename}."
end

def bucket_category(hash, all_categories)
  category = hash[:category].to_sym
  # domain = hash.domain.to_sym
  all_categories[category] ||= {}
  # all_categories[category][domain] ||= {}
  all_categories[category][:imps]  ||= 0
  all_categories[category][:imps]
  all_categories[category][:viewed_imps]  ||= 0
  all_categories[category][:clicks]  ||= 0
  all_categories[category][:convs]  ||= 0

  all_categories[category][:imps] += hash[:imps]
  all_categories[category][:viewed_imps] += hash[:viewed_imps]
  all_categories[category][:clicks] += hash[:clicks]
  all_categories[category][:convs] += hash[:convs]
end

def get_total_values(all_categories)
  total_imps = 0
  total_viewed_imps = 0
  total_clicks = 0
  total_convs = 0

  all_categories.each do |category, values|
    total_imps += values[:imps]
    total_viewed_imps += values[:viewed_imps]
    total_clicks += values[:clicks]
    total_convs += values[:convs]
  end
  total_values = {}
  total_values[:imps] = total_imps
  total_values[:viewed_imps] = total_viewed_imps
  total_values[:clicks] = total_clicks
  total_values[:convs] = total_convs
  total_values
end

def add_calculated_fields(all_categories, total_values)
  all_categories.each do |category, values|
    values[:clicks] > 0 ? values[:click_rate] = values[:clicks].to_f / values[:imps].to_f : values[:click_rate] = 0
    values[:convs] > 0 ? values[:conv_rate] = values[:convs].to_f / values[:imps].to_f : values[:conv_rate] = 0
    values[:relative_performance] = (values[:convs].to_f / total_values[:convs].to_f) / ( values[:imps].to_f / total_values[:imps].to_f)
  end
end

def sorter(all_categories)
  sorted_categories = all_categories.sort_by { |k, v| v[:relative_performance] }.reverse
  sorted_categories
end

# TODO: make a simple CLI and ask user which report to create..
# 1: By Category
# 2: By Domain
# ..etc
# Use choice to route to the functions above and create CSV

#runs main script, the parse_csv function
parse_csv
