###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Classes::     DragSelection, DragBox
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################
# :stopdoc:
MARGIN = 5
# :startdoc:
###############################################################################
#
#
class VirtualDrag
  #
  #
  #
  private
  def initialize(canvas)
    @canvas = canvas
    @start = @current = nil
  end

  #
  #
  #
  public
  def startDragging(x, y)
    @start = FXPoint.new x, y
    @current = FXPoint.new @start
    updateCanvas # First draw.

    self
  end

  #
  #
  #
  public
  def moveTo(x, y)
    updateCanvas # Delete old.
    @current.x, @current.y = x, y
    updateCanvas # Redraw new.

    self
  end

  #
  # Subclass will have to update the canvas to delete anything that has been
  # drawn.
  #
  # === Paramters
  # Returns: Distance moved [FXPoint]
  #
  public
  def stopDragging()
    updateCanvas # Delete.

    moved = @current - @start
    @current = @start = nil

    moved
  end

  #
  #
  #
  public
  def dragging?()
    !@start.nil?
  end

  #
  #
  #
  public
  def draw(dc); end

  #
  # This might be better extended by subclass.
  #
  protected
  def updateCanvas()
    box = bounds.grow! 1 # Should I need this?
    @canvas.update box.x, box.y, box.w, box.h
  end

  #
  #
  #
  public
  def bounds()
    FXRectangle.new [@current.x, @start.x].min, [@current.y, @start.y].min,
                    (@start.x - @current.x).abs, (@start.y - @current.y).abs
  end
end # class VirtualDrag

###############################################################################
#
#
class DragSelection < VirtualDrag

  private
  def initialize(canvas)
    super
    @draggedHotspots = nil
  end

  #
  #
  #
  public
  def startDragging(x, y, hotspots)
    # Get the full rectangle covered by the hotspots.
    bounds = hotspots.first.bounds
    @currRect = FXRectangle.new bounds.x, bounds.y, bounds.w, bounds.h

    # Copy the hotspots into the local array - these will be the ones moved
    # around.
    @draggedHotspots = Array.new

    hotspots.each do |hotspot|
      # Add together the boundary rectangles.
      @currRect += hotspot.bounds

      # Make an identical (though unselected) copy of rectangle to move.
      hs = Hotspot.new hotspot
      hs.selected = false # Just so that they are drawn more simply.
      @draggedHotspots.push hs
    end

    # Allow a bit of lea-way.
    @currRect.grow! 1

    updateCanvas

    super x, y
  end # startDragging()

  #
  # Called each time the mouse moved during the drag operation.
  #
  public
  def moveTo(x, y)
    # Calculate the amount moved before continuing.
    moveX, moveY = (x - @current.x), (y - @current.y)

    # Move the dragged hotspots.
    @draggedHotspots.each { |hotspot| hotspot.offset! moveX, moveY }

    # Just update the area where we last drew our hotspots (which need deleting)
    # and where we want to draw the new ones.
    updateCanvas
    @currRect.move! moveX, moveY
    updateCanvas

    super
  end # moveTo()

  #
  # Called at the end of a drag operation.
  #
  public
  def stopDragging()
    # Leave dragged hotspots.
    @draggedHotspots = nil

    super
  end

  #
  #
  #
  public
  def draw(dc)
    @draggedHotspots.each { |hotspot| hotspot.draw dc }
  end

  #
  # Redraw the complete area covered by the dragged items.
  #
  protected
  def updateCanvas
    @canvas.update @currRect.x, @currRect.y, @currRect.w, @currRect.h
  end

  #
  # 
  #
  public
  def hotspots
    @draggedHotspots
  end
end # DragSelection


###############################################################################
# Rubber-band box for selection purposes.
#
class DragBox < VirtualDrag
  #
  #
  #
  public
  def draw dc
#     dc.foreground =
    dc.lineWidth = 5
    box = bounds
    dc.drawHashBox box.x, box.y, box.w, box.h
  end
end

###############################################################################
#
#
class DragEdge < VirtualDrag
  public
  def draw(dc)
    dc.background = dc.foreground = Hotspot::COLOUR_EDGE
    dc.lineWidth = Hotspot::LINE_WIDTH_EDGE
    dc.drawLine @start.x, @start.y, @current.x, @current.y
  end
end # class DragEdge