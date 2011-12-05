###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Classes::     Settings
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################

require 'yaml'

###############################################################################
#
#
class Settings
  #
  # Initialize by reading in the Settings file. 
  #
  private
  def initialize(filename)
    @filename = filename

    if File.exists? @filename 
      File.open(@filename, 'r') do |file|
        @sections = YAML::load(file)
      end
    else
      @sections = Hash.new
    end

    @modified = false
  end # initialize()

  #
  # Saves the Settings to the predefined file.
  #
  public
  def save()
    if @modified
      File.open(@filename, 'w') do |file|
        file.write @sections.to_yaml
      end
      @modified = false
    end
  end

  #
  #
  #
  public
  def getValue(section, key, default)
    # Return value from section:key, else the default.
    if @sections[section] && @sections[section][key] != nil
      @sections[section][key]
    else
      default
    end
  end # value

  #
  #
  #
  public
  def setValue(section, key, value)
    # Create a new section if needed.
    unless @sections[section]
      @sections[section] = Hash.new
    end

    # Modified only if something has changed.
    if value != @sections[section][key]
      @modified = true
    end

    @sections[section][key] = value
  end # value
end
