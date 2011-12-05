###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Classes::     InfoPanelManager, InfoPanel, HotspotPanel, HotspotSelectionPanel
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################

require 'hotspots'
###############################################################################
#
#
class InfoPanelManager < FXVerticalFrame

  #
  #
  #
  private
  def initialize(parent, canvas)
    super parent

    @hotspotPanel = HotspotPanel.new self, canvas
    @selectionPanel = HotspotSelectionPanel.new self
  end # initialize()

  #
  # +data+ can be
  # * nil:: Clear all panels.
  # * Hotspot:: Show information about individual Hotspot.
  # * Array:: Show information about selection of Hotspots.
  #
  public
  def describe(data)
    case data 
    when nil
      hs, sel = nil, nil

    when HotspotList, Array
      case data.size
      when 0
        hs, sel = nil, nil
  
      when 1
        hs, sel = data.first, nil
  
      else
        hs, sel = nil, data
  
      end

    else
      raise ArgumentError, "Unknown type #{data.class}."

    end

    @hotspotPanel.hotspot, @selectionPanel.hotspots = hs, sel
   
  end # describe()
end # InfoPanelManager


###############################################################################
# A panel stored within info panels.
#
class InfoPanel < FXVerticalFrame

  TITLE_FONT_SIZE = 12

  #
  #
  #
  private
  def initialize(parent, title)
    super(parent)

    label = FXLabel.new(self, title)
    label.font = FXFont.new(app, "arial", TITLE_FONT_SIZE)
    FXHorizontalSeparator.new(self)

    hide # By default we are hidden!
  end # initialize()
  
end # class InfoPanel

###############################################################################
#
#
class HotspotPanel < InfoPanel
  attr_reader :hotspot

  # :stopdoc:
  NUM_FIELD_WIDTH = 4
  # :startdoc:

  #
  #
  #
  private
  def initialize(parent, canvas)
    super(parent, "Hotspot")

    @canvas = canvas

    @hotspot = nil
  
    # Name of hotspot
    FXLabel.new(self, "Name")

    @hotspotName = FXTextField.new(self, 0, nil, FXDataTarget::ID_VALUE,
       FRAME_SUNKEN|TEXTFIELD_NORMAL|LAYOUT_FILL_X)

    # Centre - X & Y
    FXLabel.new(self, "Centre")
    centreMatrix = FXMatrix.new self, 1, MATRIX_BY_ROWS
 
    # X position.
    FXLabel.new centreMatrix, "X: " 
    @hotspotCentreX = FXTextField.new(centreMatrix, NUM_FIELD_WIDTH, nil,
        FXDataTarget::ID_VALUE, TEXTFIELD_INTEGER|TEXTFIELD_NORMAL)

    # Y position.
    FXLabel.new centreMatrix, "Y: "
    @hotspotCentreY = FXTextField.new(centreMatrix, NUM_FIELD_WIDTH, nil,
        FXDataTarget::ID_VALUE, TEXTFIELD_INTEGER|TEXTFIELD_NORMAL)

    # Number of points in the hotspot.
    numPointsMatrix = FXMatrix.new self, 2, MATRIX_BY_COLUMNS

    FXLabel.new numPointsMatrix, "EntryCost:"
    @hotspotEntryCost = FXTextField.new(numPointsMatrix, NUM_FIELD_WIDTH, nil,
        FXDataTarget::ID_VALUE, TEXTFIELD_INTEGER|TEXTFIELD_NORMAL)

    FXLabel.new numPointsMatrix, "Number of points:" 
    @hotspotNumPoints = FXLabel.new(numPointsMatrix, '')

  end

  #
  # Sets the data in the panel to describe a certain hotspot - or clears it.
  #
  public
  def hotspot=(hotspot)
    @hotspot = hotspot

    if @hotspot
      @hotspotName.target = @hotspot.nameTarget
      @hotspotCentreX.target = @hotspot.centreXTarget
      @hotspotCentreY.target = @hotspot.centreYTarget
      @hotspotEntryCost.target = @hotspot.entryCostTarget
      @hotspotNumPoints.text = @hotspot.size.to_s
      show # Appear after the changes.

    else
      hide # Disappear before clearing.
#       @hotspotName.text = ''
      @hotspotName.target = nil
      @hotspotCentreX.target = nil
      @hotspotCentreY.target = nil
      @hotspotEntryCost.target = nil
      @hotspotCentreX.text = @hotspotCentreY.text = ''
      @hotspotNumPoints.text = ''

    end

    parent.recalc

  end

end # HotspotPanel

###############################################################################
#
#
class HotspotSelectionPanel < InfoPanel
  attr_reader :hotspots

  # :stopdoc:
  NUM_FIELD_WIDTH = 4
  # :startdoc:

  #
  #
  #
  private
  def initialize(parent)
    super(parent, "Selection")

    @hotspots = nil

    totalsMatrix = FXMatrix.new self, 2, MATRIX_BY_COLUMNS|LAYOUT_FILL_X

    # Number of Hotspot objects.
    FXLabel.new totalsMatrix, "Number of hotspots:" 
    @numHotspots = FXLabel.new(totalsMatrix, '')

    # Number of points in the Hotspot objects.
    FXLabel.new totalsMatrix, "Total points:" 
    @totalPoints = FXLabel.new(totalsMatrix, '')

  end # initialize()

  #
  # Sets the data in the panel to describe a certain number of Hotspot objects -
  # or clears it.
  #
  public
  def hotspots=(hotspots)
    @hotspots = hotspots

    if @hotspots
      @numHotspots.text = @hotspots.size.to_s

      totalPts = 0
      @hotspots.each { |hs| totalPts += hs.points.size }

      @totalPoints.text = totalPts.to_s
      show

    else
      hide
      @numHotspots.text = @totalPoints.text = ''

    end

    parent.recalc

  end # hotspots=()

end # class HotspotSelectionPanel