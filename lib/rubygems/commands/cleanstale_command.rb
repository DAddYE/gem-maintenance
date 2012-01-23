require 'rubygems/command'

class Gem::Commands::CleanstaleCommand < Gem::Command
  def initialize
    super('cleanstale', 'Remove gems without a given access time')
  end

  def arguments
    "DAYS        number of days to check, default 30"
  end

  def usage # :nodoc:
    "#{program_name} [DAYS]"
  end

  def execute
    days = get_one_optional_argument || '30'
    say "Querying for gems without access from #{days} days..."
    gem_to_atime = {}
    Gem::Specification.each do |spec|
      key = { :name => spec.name, :version => spec.version }
      Dir["#{spec.full_gem_path}/**/*.*"].each do |file|
        next if File.directory?(file)
        stat = File.stat(file)
        gem_to_atime[key] ||= stat.atime
        gem_to_atime[key] = stat.atime if gem_to_atime[key] < stat.atime
      end
    end

    gem_to_atime.sort_by { |_, atime| atime }.each do |spec, atime|
      break unless (Time.now.to_i-atime.to_i) > 3600 * 24 * days.to_i
      say "#{spec[:name]} #{spec[:version]} last access was on #{atime.strftime '%d/%m/%Y at %H:%M'}"
      cmd = "gem uninstall #{spec[:name]} -v #{spec[:version]}"
      say cmd
      system cmd
    end
  end
end
