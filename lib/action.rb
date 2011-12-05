###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Classes::     Action, MoveAction, CreateAction, DeleteAction
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/19 20:13:35 $
#
###############################################################################

require 'fox16/undolist'

###############################################################################
#
# An action is any event that can be done and undone.
# Subclasses should implement redo() and undo() methods.
#
class Action < FXCommand
  # === Parameters
  # items: The items which are affected by the action.
  #
  private
  def initialize(items)
    @items = items
  end # initialize()

  #
  # Iterates through each Hotspot, updating the screen over the full area.
  # === Parameters
  # rectChange: Will the rectangle that needs painting change? [Boolean]
  # & block(hotspot):
  protected
  def perform_each(rectChange, & block)
    @items.each do |item|

      # Update the screen if the item boundary rectangle will change.
      if rectChange
        bounds = item.drawBounds
        @@canvas.update bounds.x, bounds.y, bounds.w, bounds.h
      end

      yield item

      # Update the appropriate area of the screen.
      bounds = item.drawBounds
      @@canvas.update bounds.x, bounds.y, bounds.w, bounds.h
    end
  end # perform()

  #
  # Records the global canvas so that any Action can update it.
  #
  public
  def Action.canvas=(canvas)
    @@canvas = canvas
  end

end # class Action


###############################################################################
#
# Movement of one or more Hotspot instances.
#
class MoveAction < Action

  #
  #
  #
  private
  def initialize(items, xOffset, yOffset)
    super items
    @xOffset, @yOffset = xOffset, yOffset
  end # initialize()

  #
  # Move the Hotspot objects.
  #
  public
  def redo()
    perform_each(true) { |item| item.offset! @xOffset, @yOffset }
  end

  #
  # Move the Hotspot objects back to their original positions.
  #
  public
  def undo()
    perform_each(true) { |item| item.offset! -@xOffset, -@yOffset }
  end
end # class MoveAction



###############################################################################
#
# Creation of one or more Hotspot instances.
#
class CreateAction < Action

  #
  #
  #
  private
  def initialize(items, container)
    super items
    @container = container
  end # initialize()

  #
  #
  #
  public
  def redo
    perform_each(false) { |hotspot| @container.add hotspot }
  end

  #
  #
  #
  public
  def undo
    perform_each(false) { |hotspot| @container.remove hotspot }
  end
end # class CreateHotspotAction


###############################################################################
#
# Deletion of one or more Hotspot instances.
# 
class DeleteAction < Action

  #
  #
  #
  private
  def initialize(items, container)
    super items
    @container = container
  end # initialize()

  #
  #
  #
  public
  def redo
    perform_each(false) { |hotspot| @container.remove hotspot }
  end # do()

  #
  #
  #
  public
  def undo
    perform_each(false) { |hotspot| @container.add hotspot }
  end # undo()
end # class DeleteAction