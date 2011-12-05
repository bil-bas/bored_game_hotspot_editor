###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Classes::     HotspotList, Hotspot, PartialHotspot
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################

require 'fox16'
include Fox

###############################################################################
# A list of Hotspot objects.
#
class HotspotList

  PATTERN = "Hotspot files (*.hsl)"

  #
  # Creates a new list for storing Hotspot objects.
  # Optionally, the +doc+ argument is the REXML docuent to read from to
  # initialise the list.
  #
  private
  def initialize(doc = nil)
    @hotspots = Array.new

    loadSVG(doc) if doc
  end # initialize()
  
  # 
  # Saves the hotspot list into a REXML document.
  #
  public
  def saveSVG(doc)
    @hotspots.each do |hotspot|
      hotspot.saveSVG doc
    end
  end # saveTo()

  #
  # Restores the hotspot list from a REXML element.
  #
  public
  def loadSVG(doc)
    @hotspots.clear

    doc.elements.each("g") do |group|
      @hotspots.push Hotspot.new(group)
    end
  end # loadFrom()

  #
  # Draws all of the Hotspot objects.
  #
  public
  def draw(dc)
    if size > 0
      @hotspots.each { |hotspot| hotspot.draw dc }
  
      # Draw a focus around the all of the selected hotspots.
      selected = selectedHotspots
      if selected.size > 0
        box = selected.first.bounds
        selected.each { |hotspot| box += hotspot.bounds }
        dc.drawFocusRectangle box.x, box.y, box.w, box.h
      end
    end
  end # draw()

  #
  # Returns the first Hotspot at position x, y (in pixels). If no hotspots are
  # found, returns nil.
  #
  public
  def hotspotAt(x, y)
    @hotspots.reverse_each do |hotspot|
      return hotspot if hotspot.contains? x, y
    end

    return nil
  end # hotspotAt)_

  # Returns a list of all the Hotspot objects at position x, y (in pixels).
  #
  public
  def allHotspotsAt(x, y)
    contained = Array.new

    # Order of checking isn't relevant.
    @hotspots.each do |hotspot|
      contained.push hotspot if hotspot.contains? x, y
    end

    contained
  end # allHotspotsAt()

  # 
  # Gets a list of currently selected Hotspot objects.
  #
  public
  def selectedHotspots()
    @hotspots.select { |hotspot| hotspot.selected? }
  end

  # 
  # Offsets the position of all Hotspot objects by x, y (in pixels).
  #
  public
  def offset!(x, y)
    @hotspots.each do |hotspot|
      hotspot.offset x, y
    end

    self
  end # offset!()

  #
  #
  #
  public
  def add(hotspot)
    @hotspots.push hotspot
  end

  # 
  #
  #
  public
  def remove(hotspot)
    @hotspots.delete hotspot
  end

  # 
  #
  #
  public
  def size()
    @hotspots.size
  end

  # 
  #
  #
  public
  def clear()
    @hotspots.clear
  end

  # 
  #
  #
  public
  def each()
    @hotspots.each { |hotspot| yield hotspot }
  end

  # 
  #
  #
  public
  def each_selected()
    selectedHotspots { |hotspot| yield hotspot }
  end

  # 
  #
  #
  public
  def first()
    @hotspots.first
  end

  # 
  #
  #
  public
  def empty?()
    @hotspots.empty?
  end
end # class HotspotList


###############################################################################
# A hotspot for detecting mouse hover.
#
class Hotspot
  # Name of the hotspot. It is automatically generated when the Hotspot is first
  # created.
  public
  attr_reader :points
  attr_reader :edges
  attr_reader :nameTarget
  attr_reader :centreXTarget
  attr_reader :centreYTarget
  attr_reader :entryCostTarget

  public
  def name
    @nameTarget.value
  end

  public
  def name=(value)
    @nameTarget.value = value
  end

  public
  def centreX
    @centreXTarget.value
  end

  public
  def centreX=(value)
    @centreXTarget.value = value
  end

  public
  def centreY
    @centreYTarget.value
  end

  public
  def centreY=(value)
    @centreYTarget.value = value
  end

  public
  def entryCost
    @entryCostTarget.value
  end

  public
  def entryCost=(value)
    @entryCostTarget.value = value
  end

  COLOUR_FILL   = FXRGB(0xFF, 0xFF, 0xFF)
  COLOUR_LINE   = FXRGB(0x00, 0x00, 0x00)
  COLOUR_CENTRE = FXRGB(0xFF, 0x00, 0x00) # Centre crosshair.

  COLOUR_EDGE   = FXRGB(0x00, 0xAA, 0x00)
  LINE_WIDTH_EDGE = 1

  POINT_WIDTH   = 4 # Must be odd.

  DEF_ENTRY_COST = 1

  # Length of the arm of the centre-position cross. Cross is twice this in
  # height and width.
  CROSS_LEN = 6

  # Current number of hotspots. Used to automatically generate unique names.
  @@hotspotNum = 0

  #
  # arg can be either:
  # * PartialHotspot (in which case the optional +name+ parameter will override
  #                   the automatically generated name)
  # * REXML::Element
  #
  private
  def initialize(arg, name = nil)
    @points = Array.new

    @nameTarget    = FXDataTarget.new
    @centreXTarget = FXDataTarget.new
    @centreYTarget = FXDataTarget.new
    @entryCostTarget = FXDataTarget.new

    @centreXTarget.connect(SEL_COMMAND) { |sender, sel, data|
#       update
    }
    @centreYTarget.connect(SEL_COMMAND) { |sender, sel, data|
#       update
    }
    @entryCostTarget.connect(SEL_COMMAND) { |sender, sel, data|
      sender.value = 0 if !data || data < 0 
#       update
    }

    case arg
    when REXML::Element
      loadSVG arg

    when PartialHotspot
      arg.each { |point| @points.push point }

      # Generate a unique name unless one has been specified
      if name
        self.name = name
      else
        @@hotspotNum += 1
        self.name = "hotspot_#{@@hotspotNum}"
      end

    when Hotspot
      self.name = arg.name
      self.centreX, self.centreY = arg.centreX, arg.centreY
      arg.points.each { |point| points.push FXPoint.new(point) }

    else
      raise
    end

    @region = FXRegion.new @points

    # Calculate default centre.
    if arg.kind_of? PartialHotspot
      box = @region.bounds
      self.centreX = (box.x + (box.w / 2))
      self.centreY = (box.y + (box.h / 2))
      self.entryCost = DEF_ENTRY_COST
    end

    @selected = false

    @hotspotPoints = Array.new
    @edges = Array.new
  end # initialize()

  # 
  # Saves information about the Hotspot to a REXML document.
  #
  public
  def saveSVG(doc)
    hotspotElem = doc.add_element "g"
    hotspotElem.add_attributes "id"           => name,
                               "stroke-width" => "1",
                               "fill"         => "none"

    polygon = hotspotElem.add_element "polygon"

    pointsStr = ''

    @points.each do |fxpoint|
      pointsStr += "#{fxpoint.x},#{fxpoint.y} "
    end

    polygon.add_attributes "fill"         => "none",
                           "stroke"       => "black",
                           "points"       => pointsStr.chomp(' ')


    centreElem = hotspotElem.add_element "rect"
    centreElem.add_attributes "x"      => self.centreX.to_s,
                              "y"      => self.centreY.to_s,
                              "width"  => "1",
                              "height" => "1",
                              "stroke" => "red"

  end # saveTo()

  #
  # Restores information about the Hotspot from a REXML document.
  #
  public
  def loadSVG(hotspotElem)
    @points.clear

    # Name
    name = hotspotElem.attributes["id"]

    # Centre
    centreElem = hotspotElem.elements["rect"]
    if centreElem
      self.centreX = centreElem.attributes["x"].to_i
      self.centreY = centreElem.attributes["y"].to_i
    end

    # Points array
    polygonElem = hotspotElem.elements["polygon"]

    # Read from the points string "x1,y1 x2,y2 x3,y3".
    pointsStr = polygonElem.attributes["points"]

    while pointsStr =~ /^\s*?([+\-]?\d+),([+\-]?\d+)(?:\s+,?|,|$)/
      @points.push FXPoint.new($1.to_i, $2.to_i)
      pointsStr = $'
    end

  end # loadFrom()

  #
  # Draws the Hotspot. If the Hotspot has been selected, then additionally draws
  # a focus box and a crosshair at the centre position.
  #
  public
  def draw(dc)
#         dc.foreground = COLOUR_FILL
#         dc.background = COLOUR_LINE
#         dc.fillStyle = FILL_STIPPLED
#         dc.stipple = STIPPLE_2
#         dc.function = BLT_SRC_XOR_DST
#         dc.fillPolygon self

    # Draw the points and close the two ends.
    dc.lineStyle = LINE_SOLID
    dc.foreground = FXRGB(0x00, 0xff, 0xff)
    dc.fillPolygon @points
    dc.foreground = COLOUR_LINE
    dc.drawLines @points
    dc.drawLine @points.first.x, @points.first.y, @points.last.x, @points.last.y

    if @selected
      # Indicate the centre-point.
      dc.foreground = COLOUR_CENTRE
      dc.drawLine((centreX - CROSS_LEN), centreY,
                  (centreX + CROSS_LEN), centreY)
      dc.drawLine(centreX, (centreY - CROSS_LEN),
                  centreX, (centreY + CROSS_LEN))

      @hotspotPoints.each { |hsPoint| hsPoint.draw dc }
    end

#     # Indicate the entryCost.
#     dc.background = FXRGB(0x00, 0x00, 0x00)
#     dc.foreground = FXRGB(0xFF, 0xFF, 0xFF)
#     dc.fillCircle(centreX, centreY, CROSS_LEN)
#     font = FXFont.new dc.app, "arial" 
# #     font.create
# #     dc.font = font
#     
# #     dc.drawText(centreX, centreY, "fred")

  end # draw()

  #
  # TODO: Only show edges to Hotspot instances that are visible
  # (e.g. not CUT out).
  #
  public
  def drawEdges(dc)
    dc.foreground = dc.background = COLOUR_EDGE
    dc.lineWidth = LINE_WIDTH_EDGE

    @edges.each do |target|
      if target.edges.index self
        dc.drawLine(centreX, centreY, target.centreX, target.centreY)
      else
        dc.drawArrowLine(centreX, centreY, target.centreX, target.centreY,
                         FXDC::ARROW_AT_MIDDLE)
      end
    end
  end

  #
  # Does the Hotspot contain the position +x+, +y+ pixels.
  # === Parameters
  # +x+::
  # +y+::
  #
  public
  def contains?(x, y)
    @region.contains? x, y
  end

  # 
  # What is the boundary of the hotspot region? (FXRectangle)
  #
  public
  def bounds()
    @region.bounds
  end

  # 
  # What is the boundary of the hotspot region? (FXRectangle)
  # It will be slightly larger if selection means that its points are shown.
  #
  public
  def drawBounds()
    if @selected
      bounds.grow!(POINT_WIDTH / 2)
    else
      bounds
    end
  end # drawBounds()

  #
  # Offsets the hotspot region and centre position by +x+, +y+ pixels.
  #
  public
  def offset!(x, y)
    # Move region points.
    @region.offset! x, y

    # Move local copy of points.
    @points.each do |point|
      point.x += x
      point.y += y
    end

    @hotspotPoints.each { |hsPoint| hsPoint.offset! x, y }

    # Move centre-position
    self.centreX += x
    self.centreY += y

    self
  end # offset!()

  #
  # Has the Hotspot been selected by the user?
  #
  public
  def selected?()
    @selected
  end

  #
  # 
  #
  public
  def size()
    @points.size
  end

  #
  # 
  #
  public
  def selected=(selected)
    if selected != @selected
      @selected = selected

      # Create or delete the vertex points list.
      if @selected
        @points.each do |point|
          @hotspotPoints.push HotspotPoint.new(point, POINT_WIDTH)
        end
      else
        @hotspotPoints.clear
      end
    end
  end # selected=()

  #
  #
  #
  public
  def addEdge(target, biDirectional = false)
    @edges.push target
    target.addEdge(self) if biDirectional
  end

  #
  #
  #
  public
  def removeEdge(target)
    @edges.delete target
  end

end # class Hotspot

###############################################################################
# A partial hotspot, created while drawing a proper Hotspot.
#
class PartialHotspot < Array
  # :stopdoc:
  COLOUR_LINE = FXRGB(0x00, 0x00, 0x00)
  # :startdoc:

  #
  # Draws the current path.
  #
  public
  def draw(dc)
    dc.foreground = COLOUR_LINE

    # Draw the path. Use a point if we only have one +FXPoint+.
    if size == 1
      dc.drawPoint self.first.x, self.first.y
    else
#       dc.lineStyle = LINE_SOLID
      dc.drawLines self
    end
  end # draw()

  # 
  # Can the path be closed yet? A Hotspot should only be created (closed) if it
  # has at least 3 points.
  #
  public
  def closable?()
    size >= 3 
  end

end # class PartialHotspot

###############################################################################
#
#
class HotspotPoint
  COLOUR_POINT  = FXRGB(0xFF, 0x00, 0x00)

  #
  #
  #
  private
  def initialize(point, width)
    @point = point
    @region = FXRegion.new @point.x - (width / 2), @point.y - (width / 2),
                           width, width
  end # initialize()

  #
  # Draws the HotspotPoint.
  #
  public
  def draw(dc)
    dc.foreground = COLOUR_POINT

    box = @region.bounds
    dc.fillRectangle box.x, box.y, box.w, box.h

  end # draw()

  #
  # Moves the HotspotPoint.
  #
  public
  def offset!(x, y)
    @region.offset! x, y
  end
end # class HotspotPoint

###############################################################################
# Tempoary FUDGE.
#
class FXRegion
  alias :oldBounds :bounds

  public
  def bounds
    oldBounds.grow! 0, 1, 0, 1 # Should be little bit higher and wider.
  end
end

###############################################################################
#
class FXDC
  DEF_ARROW_LENGTH = 10
  DEF_ARROW_ANGLE  = 45.0

  ARROW_AT_END    = 0b01
  ARROW_AT_MIDDLE = 0b10
  ARROW_NORMAL    = ARROW_AT_END

  # 
  # Draws a line with a filled arrow head on the end. The line will be drawn
  # using the dc's lineColor, the arrow using the dc's fillColor.
  # Uses a pie-wedge to draw the arrowhead, so it looks 'better' for relatively
  # small values of angle (and length).
  #
  # === Parameters
  # +x1+::     X coordinate of start of line [Integer]
  # +y1+::     Y coordinate of start of line [Integer]
  # +x2+::     X coordinate of end of line [Integer]
  # +y2+::     Y coordinate of end of line [Integer]
  # +opts+::   
  # +length+:: Length of arrow head, back from end of line [Integer]
  # +angle+::  Angle of pie made by arrow head [Integer]
  #
  public
  def drawArrowLine(x1, y1, x2, y2, opts = ARROW_NORMAL,
                    length = DEF_ARROW_LENGTH, angle = DEF_ARROW_ANGLE) 
    drawLine(x1, y1, x2, y2)

    # Calculate the angle of the line (from desination TO source).
    thetaRad = Math::atan2((y2 - y1), (x1 - x2))
    thetaDeg = (thetaRad * 180.0) / Math::PI

    # Calculate the starting angle of the pie wedge we are going to draw.
    startDeg = thetaDeg - (angle / 2.0)

    # Draw pie wedge arrow (default at end of arrow).
    if (opts & ARROW_AT_END).nonzero?
      tipX, tipY = x2, y2

    elsif (opts & ARROW_AT_MIDDLE).nonzero?
      minX, minY = [x1, x2].min,  [y1, y2].min
      maxX, maxY = [x1, x2].max,  [y1, y2].max
      tipX = (((maxX - minX) / 2.0)).round + minX
      tipY = (((maxY - minY) / 2.0)).round + minY
    end

    pieDiam = length * 2
    fillArc((tipX - length), (tipY - length), pieDiam, pieDiam,
            (startDeg * 64), (angle * 64))
  end # drawArrowLine
end
