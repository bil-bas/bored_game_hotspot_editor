###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Classes::     VirtualMode, VirtualDrawMode,
#               DrawRectMode, DrawPolygonMode, DrawPencilMode, SelectMode,
#               FXPoint (extended)
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################
require 'drag'
require 'menu'

require 'fox16'

include Fox

###############################################################################
#
#
class VirtualMode

  # Return values from events - whether we have dealt with that event.
  EVENT_ACCEPTED = 1
  EVENT_IGNORED  = 0

  #
  #
  #
  private
  def initialize()
    @leftMouseDown = false
  end

  public 
  def VirtualMode.setClassVars(canvas, hotspotList, undoList, posPanel)
    @@canvas, @@hotspotList, @@undoList, @@posPanel =
        canvas, hotspotList, undoList, posPanel
  end

  public
  def canvas;      @@canvas;      end
  def hotspotList; @@hotspotList; end
  def undoList;    @@undoList;    end
  def posPanel;    @@posPanel;    end

  public
  def start(oldMode)
    canvas.update
  end

  public
  def finish(newMode)
  end

  public
  def onMouseEnter(event)
    posPanel.text = "#{event.win_x}, #{event.win_y} "
  end

  def onMouseLeave(event)
    posPanel.text = ""
  end

  def onMouseMove(event)
    posPanel.text = "#{event.win_x}, #{event.win_y} "
  end

  def onKeyPress(event);     end
  def onPaint(event);        end
  def onRightMouseUp(event); end

  #
  #
  #
  public
  def onLeftMouseDown(event)
    @leftMouseDown = true
  end

  #
  #
  #
  public
  def onLeftMouseUp(event)
    @leftMouseDown = false
  end

  #
  # Update an area of the canvas including both points (+x1+, +y1+) and
  # (+x2+, +y2+)
  #
  #
  public
  def updateRectangle(x1, y1, x2, y2)
    left,  top    = [x1, x2].min - 1, [y1, y2].min - 1
    right, bottom = [x1, x2].max + 1, [y1, y2].max + 1

    canvas.update left, top, (right - left).abs, (bottom - top).abs
  end
  
end # class VirtualMode

###############################################################################
#
#
class VirtualDrawMode < VirtualMode

  COLOUR_LINE = FXRGB(0x00, 0x00, 0xFF)

  MIN_DRAW_DIST = 8

  #
  #
  #
  private
  def initialize(*args)
    super

    @mousePos = nil

    @partialHotspot = nil # Hotspot we are currently drawing.
  end # initialize()

  #
  #
  #
  public
  def start(oldMode)
    @mousePos = nil
    @partialHotspot = nil

    super
  end

  #
  #
  #
  public
  def onMouseEnter(event)
    super

    if @partialHotspot
      @mousePos = FXPoint.new event.win_x, event.win_y
      updateRectangle @mousePos.x, @mousePos.y,
                      @partialHotspot.last.x, @partialHotspot.last.y
    end
  end # onEnter()

  #
  #
  #
  public
  def onMouseLeave(event)
    super

    if @partialHotspot
      updateRectangle @mousePos.x, @mousePos.y,
                      @partialHotspot.last.x, @partialHotspot.last.y
      @mousePos = nil
    end
  end # onExit()

  #
  #
  #
  public
  def onKeyPress(event)
    case event.code
    when KEY_BackSpace
      # Remove last drawn point when in the middle of drawing.
      if @partialHotspot
        @partialHotspot.pop
        if @partialHotspot.empty?
          @partialHotspot = nil
        end
        canvas.update
        return EVENT_ACCEPTED
      end

    when KEY_Escape
      # Remove the incomplete hotspot.
      if @partialHotspot
        @partialHotspot = nil
        canvas.update
        return EVENT_ACCEPTED
      end
    end

    return EVENT_IGNORED
  end

  #
  #
  #
  public
  def onMouseMove(event)
    super
    if @partialHotspot
      # Delete old.
      if @mousePos
        updateRectangle @mousePos.x, @mousePos.y,
                        @partialHotspot.last.x, @partialHotspot.last.y
      end

      # @mousePos.x, @mousePos.y = event.win_x, event.win_y # Why doesn't work?
      @mousePos = FXPoint.new event.win_x, event.win_y

      # Draw new.
      updateRectangle @mousePos.x, @mousePos.y,
                      @partialHotspot.last.x, @partialHotspot.last.y
    end
  end

  #
  #
  #
  public
  def onLeftMouseDown(event)
    super
    @mousePos = FXPoint.new event.win_x, event.win_y
  end

end # class DrawMode

###############################################################################
#
#
class DrawRectMode < VirtualDrawMode
  #
  #
  #
  public
  def onPaint(dc)
    if @partialHotspot
      last = @partialHotspot.last
      x, y = [last.x, @mousePos.x].min, [last.y, @mousePos.y].min
      w, h = (last.x - @mousePos.x).abs, (last.y - @mousePos.y).abs
      dc.foreground = COLOUR_LINE
      dc.drawRectangle x, y, w, h
    end
  end # onPaint()

  #
  #
  #
  public
  def onLeftMouseDown(event)
    super

    # Keep drawing the same line unless we aren't drawing one.
    @partialHotspot = PartialHotspot.new unless @partialHotspot
    @partialHotspot.push @mousePos

    updateRectangle @mousePos.x, @mousePos.y,
                    @partialHotspot.last.x, @partialHotspot.last.y
  end # onLeftMouseDown()

  #
  #
  #
  public
  def onLeftMouseUp(event)
    super

    # Finish drawing the rectangle.
    if @partialHotspot
      startPos = @partialHotspot.last
      currPos = FXPoint.new(event.win_x, event.win_y)

      if ((startPos.x - currPos.x).abs > MIN_DRAW_DIST &&
         (startPos.y - currPos.y).abs > MIN_DRAW_DIST)

        @partialHotspot.push FXPoint.new(startPos.x, event.win_y) 
        @partialHotspot.push currPos
        @partialHotspot.push FXPoint.new(event.win_x, startPos.y)
        hotspots = [ Hotspot.new(@partialHotspot) ]
        undoList.add CreateAction.new(hotspots, hotspotList), true
        @modified = true

      else # Rectangle too small.
        # Delete the focus rectangle.
        updateRectangle @mousePos.x, @mousePos.y,
                        @partialHotspot.last.x, @partialHotspot.last.y
      end
  
      @partialHotspot = nil

    end
  end # onLeftMouseUp(
end 

###############################################################################
#
#
class DrawPolygonMode < VirtualDrawMode
  #
  #
  #
  public
  def onPaint(dc)
    if @partialHotspot
      @partialHotspot.draw dc
      # Draw line from end of hotspot-line to mouse.
      if @mousePos
        dc.foreground = COLOUR_LINE
        dc.drawLine @partialHotspot.last.x, @partialHotspot.last.y,
                    @mousePos.x, @mousePos.y
      end
    end
  end # onPaint()

  #
  #
  #
  public
  def onLeftMouseDown(event)
    # Add another point to the hotspot we are drawing.
    super
  


    if @partialHotspot    
      if @mousePos.distanceTo(@partialHotspot.last) >= MIN_DRAW_DIST
        updateRectangle @mousePos.x, @mousePos.y,
                        @partialHotspot.last.x, @partialHotspot.last.y
        @partialHotspot.push @mousePos
      end

    else
      @partialHotspot = PartialHotspot.new
      @partialHotspot.push @mousePos
      # Draw the initial point.
      updateRectangle @mousePos.x, @mousePos.y,
                      @partialHotspot.last.x, @partialHotspot.last.y
    end
  end

  #
  #
  #
  public
  def onRightMouseUp(event)
    if @partialHotspot && @partialHotspot.closable?
      # Save the current hotspot into the list.
      hotspots = [ Hotspot.new(@partialHotspot) ]

      undoList.add CreateAction.new(hotspots, hotspotList), true

      # Delete the partial line to mouse.
      updateRectangle @mousePos.x, @mousePos.y,
                      @partialHotspot.last.x, @partialHotspot.last.y

      # Ready to start a new hotspot.
      @partialHotspot = nil

      @modified = true
    end
  end
end #class DrawPolygonMode


###############################################################################
#
#
class DrawPencilMode < DrawPolygonMode
  #
  #
  #
  public
  def onMouseMove(event)
    super
    if @leftMouseDown
      # Add another point to the hotspot we are drawing. Only if we have moved
      # far enough.
      if @mousePos.distanceTo(@partialHotspot.last) >= MIN_DRAW_DIST
        @partialHotspot.push @mousePos
      end
    end
  end # onMouseMove()

  #
  #
  #
  public
  def onLeftMouseDown(event)
    super

    # Keep drawing the same line unless we aren't drawing one.
    @partialHotspot = PartialHotspot.new unless @partialHotspot

    if @mousePos.distanceTo(@partialHotspot.last) >= MIN_DRAW_DIST
      @partialHotspot.push @mousePos
    end

    canvas.update
  end
end # class DrawPencilMode

###############################################################################
#
#
class VirtualEditingMode < VirtualMode

  #
  #
  #
  public
  def VirtualEditingMode.setClassVars(infoPanels, clipBoard)
    @@infoPanels, @@clipBoard = infoPanels, clipBoard
  end

  public
  def infoPanels; @@infoPanels; end
  def clipBoard;  @@clipBoard;  end

  #
  #
  #
  public
  def finish(newMode)
    # Deselect all currently selected hotspots.
    selected = hotspotList.selectedHotspots
    if selected.size > 0
      infoPanels.describe nil
      selected.each { |hotspot| hotspot.selected = false }
    end
  end # finish()
end

###############################################################################
#
#
class SelectMode < VirtualEditingMode
  attr_reader :popupAt

  # Speed of cursor movement in pixels per event.
  MOVE_SPEED_DEFAULT = 1
  # Speed of cursor movement (with shift key down) in pixels per event.
  MOVE_SPEED_SHIFT = MOVE_SPEED_DEFAULT * 4

  #
  #
  #
  private
  def initialize()
    super

    @dragSelection = DragSelection.new canvas
    @dragBox       = DragBox.new canvas

    @popupAt = FXPoint.new 0, 0

  end # initialize()

  #
  #
  #
  public
  def onKeyPress(event)
    if event.code == KEY_Delete
      # Delete any selected hotspots.
      hotspots = hotspotList.selectedHotspots
      numSelected = hotspots.size
      if numSelected > 0
        numText = if numSelected == 1
                    "this hotspot"
                  else
                    "these #{numSelected} hotspots"
                  end
        if ((event.state & CONTROLMASK) != 0) || 
           FXMessageBox.question(canvas, MBOX_OK_CANCEL,
           "Confirm deletion",
           "Do you really want to delete #{numText}?\n") == MBOX_CLICKED_OK
         
          undoList.add DeleteAction.new(hotspots, hotspotList), true

          infoPanels.describe nil

          return EVENT_ACCEPTED
        end
      end

    else # Check cursor keys.
      # Move faster if shift is held down.
      moveBy = if (event.state & SHIFTMASK) != 0
                 MOVE_SPEED_SHIFT
               else
                 MOVE_SPEED_DEFAULT
               end

      case event.code
      when KEY_Up
        moveHotspots hotspotList.selectedHotspots, 0, -moveBy
        modified = true
        return EVENT_ACCEPTED
  
      when KEY_Down
        moveHotspots hotspotList.selectedHotspots, 0, moveBy
        modified = true
        return EVENT_ACCEPTED
  
      when KEY_Left
        moveHotspots hotspotList.selectedHotspots, -moveBy, 0
        modified = true
        return EVENT_ACCEPTED
         
      when KEY_Right
        moveHotspots hotspotList.selectedHotspots, moveBy, 0
        modified = true
        return EVENT_ACCEPTED
      end

    end
  end

  #
  #
  #
  public
  def onMouseMove(event)
    super
    if @leftMouseDown
      if @dragSelection.dragging?
        @dragSelection.moveTo event.win_x, event.win_y
#TODO: This is a very inefficient way to update the panel info.
        sel = @dragSelection.hotspots
        infoPanels.describe sel if sel.size == 1
  
      elsif @dragBox.dragging?
        @dragBox.moveTo event.win_x, event.win_y

      end
    end
  end

  #
  #
  #
  public
  def onLeftMouseDown(event)
    super

    clickedHotspot = hotspotList.hotspotAt event.win_x, event.win_y

    if clickedHotspot
      if (event.state & SHIFTMASK) != 0
        # If SHIFT is down, toggle state of clicked Hotspot.
        clickedHotspot.selected = !clickedHotspot.selected?

        # Fill in the Hotspot details if there is only one now selected.
        infoPanels.describe hotspotList.selectedHotspots
          
        canvas.update

      else # Shift key up.
        # Select the Hotspot, unless it is already selected.
        unless clickedHotspot.selected?
          infoPanels.describe [ clickedHotspot ]

          # The clicked Hotspot becomes the only selected one.
          hotspotList.selectedHotspots.each do |hotspot|
            hotspot.selected = false
          end
          clickedHotspot.selected = true

          canvas.update
        end
      end

      # Potential drag start.
      if clickedHotspot.selected?
        @dragSelection.startDragging event.win_x, event.win_y,
                                     hotspotList.selectedHotspots
                                     
      end
    else # !clickedHotspot
      if (event.state & SHIFTMASK) == 0 # Without shift...clear selection.
        # Unselect any currently selected hotspots.
        selected = hotspotList.selectedHotspots
        if selected.size > 0
          selected.each { |hotspot| hotspot.selected = false }
#             infoPanels.describe nil # Done by drag-box.
          canvas.update 
        end
      end

      @dragBox.startDragging event.win_x, event.win_y

    end
  end # onLeftMouseDown()

  #
  #
  #
  public
  def onLeftMouseUp(event)
   super

   if @dragSelection.dragging?
      move = @dragSelection.stopDragging
      undoList.add MoveAction.new(hotspotList.selectedHotspots, move.x, move.y),
                    true
    
    elsif @dragBox.dragging?
      # Select all the hotspots under the final dragbox.
      rect = @dragBox.bounds
      hotspotList.each do |hotspot|
        if rect.contains? hotspot.bounds
          hotspot.selected = true
        end
      end
  
      infoPanels.describe hotspotList.selectedHotspots
      @dragBox.stopDragging # This will update the correct area.

    end
  end # onLeftMouseUp()

  #
  #
  #
  public
  def onRightMouseUp(event)
    if !event.moved? # TODO: Find out what this means!!!
      target = canvas.parent.parent.parent # TODO: need to make this less grim

      pane = PopupMenu.new canvas, File.open("../lib/context_menu.yml"), target
      pane.create

      @popupAt.x = event.win_x
      @popupAt.y = event.win_y
      over = hotspotList.hotspotAt(event.win_x, event.win_y)
      if over
        # Send a left-click message to select the hotspot...
        unless over.selected?
          onLeftMouseDown event
          onLeftMouseUp event
        end

      else
        pane[:cut].disable
        pane[:copy].disable
      end

      # Paste if there is anything in the clipBoard.
      if clipBoard.empty?
        pane[:paste].disable
      end

      pane.runModal event.root_x, event.root_y

    end
  end # onRightMouseUp()

  #
  #
  #
  public
  def onPaint(dc)
    if @leftMouseDown
      if @dragBox.dragging?
        @dragBox.draw dc

      elsif @dragSelection.dragging?
        @dragSelection.draw dc
      end
    end
  end

  #
  # Moves a set of hotspots all at once.
  #
  private
  def moveHotspots(hotspots, x, y)
    # Alter the description, but only if we have only one hotspot selected.
    if hotspots.size == 1
      infoPanels.describe hotspots
    end

    # Move the hotspots.

    if hotspots.size != 0
      hotspots.each do |hotspot|
        box = hotspot.drawBounds
        canvas.update box.x, box.y, box.w, box.h

        hotspot.offset! x, y

        box = hotspot.drawBounds
        canvas.update box.x, box.y, box.w, box.h
      end

      @modified = true
    end
  end # moveHotspots()
end # class SelectMode

###############################################################################
#
#
class EditHotspotMode < VirtualEditingMode
  #
  #
  #
  private
  def initialize(*args)
    super
    @dragEdge = DragEdge.new canvas
  end

  #
  #
  #
  public
  def onPaint(dc)
    hotspotList.selectedHotspots.each { |hotspot| hotspot.drawEdges dc }

    if @dragEdge.dragging?
      @dragEdge.draw dc
    end
  end
  #
  #
  #
  public
  def onLeftMouseDown(event)
    super

    clickedHotspot = hotspotList.hotspotAt event.win_x, event.win_y

    if clickedHotspot
      # Select the Hotspot, unless it is already selected.
      unless clickedHotspot.selected?
        infoPanels.describe [ clickedHotspot ]

        # The clicked Hotspot becomes the only selected one.
        hotspotList.selectedHotspots.each do |hotspot|
          # Delete the hotspot BEFORE de-selecting it.
          box = hotspot.drawBounds
          canvas.update box.x, box.y, box.w, box.h
 
          # Delete the edges.
          hotspot.edges.each do |edge|
            updateRectangle hotspot.centreX, hotspot.centreY,
                           edge.centreX, edge.centreY
          end

          hotspot.selected = false
        end
        clickedHotspot.selected = true

        box = clickedHotspot.drawBounds
        canvas.update box.x, box.y, box.w, box.h
        # Draw the new edges.
        clickedHotspot.edges.each do |edge|
          updateRectangle clickedHotspot.centreX, clickedHotspot.centreY,
                         edge.centreX, edge.centreY
        end
      end

      @dragEdge.startDragging event.win_x, event.win_y
    end
  end # onLeftMouseDown()

  #
  #
  #
  public
  def onMouseMove(event)
    super
    if @leftMouseDown && @dragEdge.dragging?
      @dragEdge.moveTo event.win_x, event.win_y
    end
  end

  #
  #
  #
  public
  def onLeftMouseUp(event)
    super
    
    if @dragEdge.dragging?
      over = hotspotList.hotspotAt event.win_x, event.win_y

      # Create an edge if we are over a different hotspot and we are not
      # already connected.
      source = hotspotList.selectedHotspots.first
      if over && (over != source) && !source.edges.index(over)
        source.addEdge over
#         over.addEdge source
        # Redraw the new edge.
      updateRectangle source.centreX, source.centreY,
                      over.centreX, over.centreY
       
      end

      @dragEdge.stopDragging # This will update the correct area.
    end
  end # onLeftMouseUp()
end # class EditHotspotMode

###############################################################################
#
# Extend FXPoint so that we can measure the distance between two points.
#
class FXPoint
  #
  # Measures the absolute (as crow flies) distance to another FXPoint.
  #
  # === Parameters
  # +point+:: Point to measure distance to [FXPoint].
  #
  public
  def distanceTo(point)
    xDiff = (x - point.x)
    yDiff = (y - point.y)
    return Math.sqrt((xDiff * xDiff) + (yDiff * yDiff))
  end # distanceTo()

end # class FXPoint