#!/usr/local/bin/ruby

# Calculation of angle to each site, from their distribution tower.
# Generates json, suitable for inserting into site_angles.html tower_data {}.

require 'vincenty'
require 'wikk_sql'
require 'wikk_configuration'

load '/wikk/etc/wikk.conf' unless defined? WIKK_CONF
require "#{RLIB}/linz/pointcloud.rb"

# initialize stuff
def init
  @mysql_conf = WIKK::Configuration.new(MYSQL_CONF)
  @dist_sites = {}
  @elevations = Point_Cloud.new # LINZ lidar altitude readings for our region.
end

def fetch_sites
  site_query = <<~SQL
    SELECT c.site_name as 'c.site_name', c.latitude as 'c.latitude', c.longitude as 'c.longitude', c.height as 'c.height',
           d.site_name as 'd.site_name', d.latitude as 'd.latitude', d.longitude as 'd.longitude', d.height as 'd.height'
    FROM customer AS c, distribution AS d, customer_distribution
    WHERE c.active = 1
    AND c.cabled = 0
    AND c.customer_id = customer_distribution.customer_id
    AND customer_distribution.distribution_id = d.distribution_id
    AND d.active = 1
    ORDER BY 'd.site_name', 'c.longitude', 'c.latitude'
  SQL

  WIKK::SQL.connect(@mysql_conf) do |sql|
    sql.each_hash(site_query) do |row|
      elevation = lookup_elevation(lat: row['d.latitude'], long: row['d.longitude'])
      distribution_site = { site_name: row['d.site_name'], latitude: row['d.latitude'].to_f, longitude: row['d.longitude'].to_f, elevation: elevation + row['d.height'].to_f }

      elevation = lookup_elevation(lat: row['c.latitude'], long: row['c.longitude'])
      customer_site = { site_name: row['c.site_name'], latitude: row['c.latitude'].to_f, longitude: row['c.longitude'].to_f, elevation: elevation + row['c.height'].to_f }

      @dist_sites[row['d.site_name']] ||= { distribution_site: distribution_site, customer_site: [] }
      @dist_sites[row['d.site_name']][:customer_site] << customer_site
    end
  end
end

def lookup_elevation(lat:, long:)
  return if lat.nil? || long.nil?

  begin
    return @elevations.elevation(Point[lat.to_f, long.to_f])
  rescue StandardError => e
    warn("lookup_elevation(lat: #{lat}, long: #{long}): #{e}")
    return 0
  end
end

def declination(ds_elev:, cs_elev:, distance:)
  return 0 if ds_elev.nil? || cs_elev.nil? || distance == 0

  begin
    return Math.atan((ds_elev - cs_elev) / distance ).to_deg
  rescue StandardError => e
    warn("declination(ds_loc: #{ds_loc}, cs_loc: #{cs_loc}, distance: #{distance}): #{e}")
    return 0
  end
end

def calculate_angles
  @dist_sites.each do |_k, v|
    max_declination = -90
    min_declination = 90
    max_distance = 0

    ds = v[:distribution_site]
    v[:customer_site].each do |cs|
      p1 = Vincenty.new(ds[:latitude], ds[:longitude])
      p2 = Vincenty.new(cs[:latitude], cs[:longitude])
      bearing_and_distance = p1.distanceAndAngle(p2)
      bearing = bearing_and_distance.bearing.to_deg

      declination_angle = declination(ds_elev: ds[:elevation], cs_elev: cs[:elevation], distance: bearing_and_distance.distance )
      min_declination = declination_angle if declination_angle < min_declination
      max_declination = declination_angle if declination_angle > max_declination

      max_distance = bearing_and_distance.distance if bearing_and_distance.distance > max_distance

      cs[:declination] = declination_angle
      cs[:bearing] = bearing
      cs[:distance] = bearing_and_distance.distance
    end

    ds[:max_declination] = max_declination
    ds[:min_declination] = min_declination
    ds[:max_distance] = max_distance
    ds[:best_declination] = (max_declination + min_declination) / 2.0
    calulate_spread(dist_record: ds, site_record: v[:customer_site])
  end
end

# Calculate the maximum angle between adjacent sites to determine the antenna coverage angle
# Guess at the best bearing for the antenna (using half the spread). May not be ideal.
def calulate_spread(dist_record:, site_record:)
  max_angle = 0
  gap_index = 0
  # Sort the sites by bearing.
  site_angle_order = site_record.sort_by { |v2| v2[:bearing] }
  (1...site_angle_order.length).each do |i|
    a = site_angle_order[i][:bearing] - site_angle_order[i - 1][:bearing]
    if a > max_angle
      max_angle = a # Angle of biggest gap (indicates where not to point the antenna :)
      gap_index = i # High side of gap.
    end
  end
  a = site_angle_order[0][:bearing] - site_angle_order[site_angle_order.length - 1][:bearing] + 360
  if a > max_angle
    max_angle = a # Angle of biggest gap (indicates where not to point the antenna :)
    gap_index = 0 # High side of gap.
  end
  dist_record[:spread] = 360 - max_angle
  # Best angle may not be midway, if there are more sites clustered in one direction, or more distant sites.
  dist_record[:best_compass_angle] = (site_angle_order[gap_index][:bearing] + dist_record[:spread] / 2) % 360
end

init

# 20 Visually distinct colours.
palette_20 = [
  { name: 'mediumslateblue', code: '#7b68ee' },
  { name: 'brown', code: '#a52a2a' },
  { name: 'seagreen', code: '#2e8b57' },
  { name: 'olive', code: '#808000' },
  { name: 'darkblue', code: '#00008b' },
  { name: 'red', code: '#ff0000' },
  { name: 'darkorange', code: '#ff8c00' },
  { name: 'gold', code: '#ffd700' },
  { name: 'springgreen', code: '#00ff7f' },
  { name: 'royalblue', code: '#4169e1' },
  { name: 'darkslateblue', code:  '#483d8b' },
  { name: 'blue', code: '#0000ff' },
  { name: 'greenyellow', code: '#adff2f' },
  { name: 'orchid', code: '#da70d6' },
  { name: 'fuchsia', code: '#ff00ff' },
  { name: 'khaki', code: '#f0e68c' },
  { name: 'deeppink', code: '#ff1493' },
  { name: 'lightsalmon', code: '#ffa07a' },
  { name: 'aquamarine', code: '#7fffd4' },
  { name: 'lightskyblue', code:  '#87cefa' }
]
fetch_sites
calculate_angles

puts '{'
@dist_sites.each do |k, v|
  puts "  \"#{k}\": {"
  puts "    distance: #{v[:distribution_site][:max_distance]},"
  puts "    min_dec: #{v[:distribution_site][:min_declination]},"
  puts "    max_dec: #{v[:distribution_site][:max_declination]},"
  puts "    max_angle: #{v[:distribution_site][:spread]},"
  puts "    best_angle: #{v[:distribution_site][:best_compass_angle]},"

  p = 0
  puts '    data: ['
  v[:customer_site].each do |v2|
    puts "    { name: \"#{v2[:site_name]}\", type: \"scatterpolar\", mode: \"lines\", line: { color: \"#{palette_20[p][:code]}\" }, theta: [0,#{v2[:bearing]}], r: [0,#{v2[:distance]}] },"
    p = (p + 1) % palette_20.length
  end
  puts '  ],'

  p = 0
  puts '    data2: ['
  v[:customer_site].each do |v2|
    if v2[:bearing] > 180
      declination = 180 - v2[:declination]
      plot_target = 'polar'
    else
      declination = v2[:declination]
      plot_target = 'polar2'
    end
    puts "      { name: \"#{v2[:site_name]}\", subplot: \"#{plot_target}\", type: \"scatterpolar\", mode: \"lines\", line: { color: \"#{palette_20[p][:code]}\" }, theta: [0,#{declination}], r: [0,#{v2[:distance]}] },"
    p = (p + 1) % palette_20.length
  end
  puts '    ]'
  puts '  },'
end
puts '  "None": { distance: 0, min_dec: 0, max_dec: 0, max_angle: 0, best_angle: 0, data: [], data2: [] }'
puts '}'
