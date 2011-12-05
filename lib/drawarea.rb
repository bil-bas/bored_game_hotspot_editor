###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Classes::     DrawArea
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################

require 'hotspots'
require 'clipboard'
require 'action'
require 'editmodes'

###############################################################################
#
#
class DrawArea < FXHorizontalFrame
  # Colour of lines to mouse.
  # :stopdoc:
  COLOUR_SCROLL_WINDOW_BACK = FXRGB(0x00, 0x00, 0x00)

  SCROLL_FRAME_THICKNESS = 4 # Otherwise scrollbars cover frame.

  # Used to calculate measurements of hexagons.
  HEIGHT_TO_SIDE_FACTOR = 2.0 * Math::cos(Math::PI / 6.0)

  DEFAULT_CANVAS_WIDTH = 500
  DEFAULT_CANVAS_HEIGHT = 400
  # :startdoc:

  # Mode of operation - Select hotspots.
  MODE_SELECT       = 0
  # Mode of operation - Editing points/edges.
  MODE_EDIT         = 1
  # Mode of operation - Draw straight lines.
  MODE_DRAW_POLYGON = 2
  # Mode of operation - Draw smooth pencil line.
  MODE_DRAW_PENCIL  = 3
  # Mode of operation - Draw rectangle.
  MODE_DRAW_RECT    = 4

  STARTUP_MODE = MODE_DRAW_POLYGON

  #
  #
  #
  private
  def initialize(parent, infoFrame, undoList, posPanel)
    super(parent, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK,
        0, 0, 0, 0, 0, 0, 0, 0)

    @infoFrame, @undoList = infoFrame, undoList

    scrollWindow = FXScrollWindow.new(self, 0,
        LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT)

    # Make it fill up the space in its frame each time we resize.
    scrollWindow.connect(SEL_CONFIGURE) { |sender, sel, event|
      sender.resize(
          (width - SCROLL_FRAME_THICKNESS),
          (height - SCROLL_FRAME_THICKNESS)
      )
    }

    scrollWindow.backColor = COLOUR_SCROLL_WINDOW_BACK

    canvasFrame = FXHorizontalFrame.new(scrollWindow)
#     canvasFrame.backColor = FXRGB(0, 0, 0) # Too harsh?

    @canvas = FXCanvas.new(canvasFrame, self, 0,
                           LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, 
                           0, 0, DEFAULT_CANVAS_WIDTH, DEFAULT_CANVAS_HEIGHT)

    @background = nil
    @backBuffer = FXImage.new(app, nil, 0, @canvas.width, @canvas.height)
    @backBuffer.create # Create it before connecting up the canvas to onPaint()

    # Attach events to appropriate methods.
    @canvas.connect(SEL_PAINT, method(:onPaint))

    # Save re-connecting, each time we change the mode.
    @canvas.connect(SEL_KEYPRESS) do |sender, sel, event|
      @mode.onKeyPress event
    end

    @canvas.connect(SEL_MOTION) do |sender, sel, event|
      @mode.onMouseMove event
    end

    @canvas.connect(SEL_LEFTBUTTONPRESS) do |sender, sel, event|
      @mode.onLeftMouseDown event
    end

    @canvas.connect(SEL_LEFTBUTTONRELEASE) do |sender, sel, event|
      @mode.onLeftMouseUp event
    end

    @canvas.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
      @mode.onRightMouseUp event
    end

    # We will show details about selected hotspot(s) here.
    @infoPanels = InfoPanelManager.new infoFrame, @canvas

    @hotspotList = HotspotList.new

    @clipBoard = ClipBoard.new @hotspotList

    # List of available modes.
    VirtualMode.setClassVars @canvas, @hotspotList, @undoList, posPanel
    VirtualEditingMode.setClassVars @infoPanels, @clipBoard

    @modes = [
      SelectMode.new,
      EditHotspotMode.new,
      DrawPolygonMode.new,
      DrawPencilMode.new,
      DrawRectMode.new
    ]

    @mode = @modes[STARTUP_MODE]

    @canvas.connect(SEL_ENTER) { |sender, sel, event|
      @mode.onMouseEnter event
    }
    @canvas.connect(SEL_LEAVE) { |sender, sel, event|
      @mode.onMouseLeave event
    }

    Action.canvas = @canvas
  end # initialize()

  #
  # Double-buffered redraw of the canvas.
  #
  public
  def onPaint(sender, sel, event)
    rect = event.rect

    # Write all the bits onto the backbuffer
    FXDCWindow.new(@backBuffer, event) do |dc|
      # Draw background image or clear with plain colour.
      if @background
        dc.drawArea @background, rect.x, rect.y, rect.w, rect.h, rect.x, rect.y
      else
        dc.foreground = @canvas.backColor
        dc.fillRectangle rect.x, rect.y, rect.w, rect.h
      end

      # Redraw the hotspots.
      @hotspotList.draw dc

      # The specific mode may have things to do.
      @mode.onPaint dc
    end

    # Copy completed image onto screen canvas.
    FXDCWindow.new(@canvas, event) do |dc|
      dc.drawArea @backBuffer, rect.x, rect.y, rect.w, rect.h, rect.x, rect.y
    end

  end # onPaint()

  #
  # TODO: Move functionality into mode.
  # +data+:: Can be event or 
  #
  public
  def commandCut(sender, sel, data)
    hotspots = @hotspotList.selectedHotspots
    if hotspots.size > 0
      if data.kind_of? FXEvent
        pos = FXPoint.new(data.win_x, data.win_y)
  
      else # Must have come from popup-menu.
        pos = @mode.popupAt
      end

      @clipBoard.cut(pos, hotspots)
      @undoList.add DeleteAction.new(hotspots, @hotspotList), true
  
      @infoPanels.describe nil
    end
  end # commandCut()

  #
  # TODO: Move functionality into mode.
  #
  public
  def commandCopy(sender, sel, data)
    hotspots = @hotspotList.selectedHotspots
    if hotspots.size > 0
      if data.kind_of? FXEvent
        pos = FXPoint.new(data.win_x, data.win_y)
  
      else # Must have come from popup-menu.
        pos = @mode.popupAt
      end

      @clipBoard.copy pos, hotspots
    end
  end # commandCopy()


  #
  # TODO: Move functionality into mode.
  #
  public
  def commandPaste(sender, sel, data)
    unless @clipBoard.empty?
      if data.kind_of? FXEvent
        pos = FXPoint.new(data.win_x, data.win_y)
  
      else # Must have come from popup-menu.
        pos = @mode.popupAt
      end

      hotspots = @clipBoard.paste(pos)
      @undoList.add CreateAction.new(hotspots, @hotspotList), true
    end
  end # commandPaste()

  #
  # TODO: Move functionality into mode.
  #
  public
  def commandSelectAll(sender, sel, event)
    if @mode.kind_of? SelectMode 
      @hotspotList.each { |hs| hs.selected = true }
  
      @infoPanels.describe @hotspotList
  
      @canvas.update # TODO: Restrict area updated.
    end
  end # commandSelectAll()

  #
  # Sets the background image. This is displayed behind any hotspots.
  #
  public
  def loadBackground(filename)
    begin
      backTmp = nil

      File.open(filename, "rb") do |file|
        backClass = case filename
                    when /\.gif$/i:        FXGIFImage
                    when /\.(jpeg|jpg)$/i: FXJPGImage
                    when /\.png$/i:        FXPNGImage
                    else
                      nil
                    end

        if backClass
          backTmp = backClass.new app, file.read
        end
      end

      if backTmp
        backTmp.create
        @background = backTmp
        @backgroundFilename = filename

        w, h = @background.width, @background.height
        @canvas.resize w, h
        @backBuffer.resize w, h

        recalc
      end

    rescue Exception => error
p "Failed to find background file: #{error}"
    end
  end # loadBackground()

  # 
  # Generates a field of rectangles.
  #
  public
  def generateRectangles(width, height, numColumns, numRows)
    # Construct grid.
    rects = Array.new numColumns
    numColumns.times { |column| rects[column] = Array.new numRows }

    numRows.times do |row|
      numColumns.times do |column|
        x, y = (column * width), (row * height)

        # Create a new hotspot via a partial one.
        part = PartialHotspot.new 
        part.push FXPoint.new(x, y)
        part.push FXPoint.new(x + width, y)
        part.push FXPoint.new(x + width, y + height)
        part.push FXPoint.new(x, y + height)
        hotspot = Hotspot.new(part, "rect_#{column}_#{row}")

        rects[column][row] = hotspot
        
      end
    end

    # Add orthagonal linking.
    numRows.times do |row|
      numColumns.times do |column|
        if column > 0
          rects[column][row].addEdge rects[column - 1][row], true
        end

        if row > 0
          rects[column][row].addEdge rects[column][row - 1], true
        end
      end
    end

    @undoList.add CreateAction.new(rects.flatten, @hotspotList), true

  end # generateRectangles()

  #
  # Generates a field of hexagons.
  #
  public
  def generateHexagons(height, numColumns, numRows)
    halfHeight = height / 2.0

    # Length of a side (== outer radius) is "height / (2 cos(PI * 30 / 180))"
    side = height / HEIGHT_TO_SIDE_FACTOR

    # Derived lengths to save time later.
    halfSide     = side * 0.5
    sideAndAHalf = side * 1.5
    diameter     = side * 2.0

    hexagons = Array.new numColumns
    numColumns.times { |column| hexagons[column] = Array.new numRows }

    numRows.times do |row|
      numColumns.times do |column|
        x, y = (column * sideAndAHalf), (row * height)

        # Shift even columns downwards. TODO: Offer either shift direction?
        if (column % 2) == 1
          y += halfHeight
        end

        # Create a new hotspot via a partial one.
        part = PartialHotspot.new 
        part.push FXPoint.new(x.round, (y + halfHeight).round)
        part.push FXPoint.new((x + halfSide).round, y.round)
        part.push FXPoint.new((x + sideAndAHalf).round, y.round)
        part.push FXPoint.new((x + diameter).round, (y + halfHeight).round)
        part.push FXPoint.new((x + sideAndAHalf).round, (y + height).round)
        part.push FXPoint.new((x + halfSide).round, (y + height).round)

        hexagons[column][row] = Hotspot.new part, "hex_#{column}_#{row}" 
      end
    end

    # Add orthagonal linking.
    numRows.times do |row|
      numColumns.times do |column|
        # Add an edge at 180degrees (down)
        if row > 0
          hexagons[column][row].addEdge hexagons[column][row - 1], true
        end

        # Allow for staggering of odd columns.
        effectRow = row
        odd = (column % 2) == 1
        effectRow += 1 if odd

        # Add an edge at 300degrees (left and up)
        if (column > 0) && (odd || (row > 0))
          hexagons[column][row].addEdge hexagons[column - 1][effectRow - 1], true
        end

        # Add an edge at 240degrees (left and down)
        if (column > 0) && (!odd || (row < (numRows - 1)))
          hexagons[column][row].addEdge hexagons[column - 1][effectRow], true
        end
      end
    end

    @undoList.add CreateAction.new(hexagons.flatten, @hotspotList), true
  end # generateHexagons()

  #
  # Changes the drawing mode.
  #
  public
  def modeNum=(newModeIndex)
    return if @modes[newModeIndex] == @mode

    # Remove effects of the old mode.
    @mode.finish @modes[newModeIndex]
   
    # Finally, update the mode itself
    oldMode = @mode

    @mode = @modes[newModeIndex]

    @mode.start oldMode
  end

  #
  # Gets the integer value for the drawing mode.
  #
  public
  def modeNum()
    @modes.index @mode
  end

  # 
  #
  #
  public
  def loadSVG(doc)
    svgElem = doc.elements["svg"]
    
    viewBoxStr = svgElem.attributes["viewBox"]
    if viewBoxStr =~ /\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*/
      @background = nil

      w, h = ($3.to_i - $1.to_i), ($4.to_i - $2.to_i)

      @canvas.resize w, h
      @backBuffer.resize w, h

      recalc
    end

    imageElem = svgElem.elements["image"]
    if imageElem
      w = imageElem.attributes["width"].to_i
      h = imageElem.attributes["height"].to_i
      loadBackground imageElem.attributes["xlink:href"]
    end

    @hotspotList.loadSVG svgElem
    @partialHotspot = nil
    @infoPanels.describe nil
    @canvas.update
  end # loadSVG()

  #
  #
  #
  public
  def saveSVG(doc)
    svgElem = doc.add_element "svg"
    svgElem.add_attributes "viewBox" => "0 0 #{@canvas.width} #{@canvas.height}",
                           "xmlns"   => "http://www.w3.org/2000/svg",
                           "version" => "1.1"
    if @background
      imageElem = svgElem.add_element "image"
      imageElem.add_attributes "x"          => "0",
                               "y"          => "0",
                               "width"      => "#{@background.width}px",
                               "height"     => "#{@background.height}px",
                               "xlink:href" => @backgroundFilename
    end

# width="12cm" height="4cm"
    @hotspotList.saveSVG svgElem

    return doc
  end # saveSVG()

  #
  #
  #
  public
  def clearHotspots()
    @hotspotList.clear
    @background = nil
    @infoPanels.describe nil
    @canvas.update
  end # clearHotspots()

end # class DrawArea