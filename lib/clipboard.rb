###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Classes::     ClipBoard
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/18 16:05:42 $
#
###############################################################################

###############################################################################
# The Clipboard stores one or more Hotspot objects.
#
class ClipBoard

  #####
  # Construct a clipboard.
  #
  # === Parameters:
  # hotspotList:: The list to copy to and from [HotspotList].
  #
  private
  def initialize(hotspotList)
    @items = Array.new
  end

  #####
  # Removes and stores all the selected Hotspot objects from the HotspotList.
  #
  # === Parameters:
  # from:: Position to cut from [FXPoint].
  #
  public
  def cut(from, items)
    copyItems from, items, false

    return items
  end # cut()

  #####
  # Removes and stores all the selected Hotspot objects from the HotspotList.
  #
  # === Parameters:
  # from:: Position to cut from [FXPoint].
  #
  public
  def copy(from, items)
    copyItems from, items, true

    return items
  end # copy()

  #####
  #
  # === Parameters:
  # from:: Position to copy from [FXPoint].
  #
  private
  def copyItems(from, items, doCopy)
    @copiedAt = from

    @items.clear
    
    items.each do |hs|
      newHS = Hotspot.new hs
      newHS.name = "copy of #{newHS.name}" if doCopy
      @items.push newHS
    end

    @items.each { |hs| hs.selected = false }

    return @items
  end # copyItems()

  #####
  # Pastes the Hotspot objects into the HotspotList.
  #
  # === Parameters:
  # at:: Position to paste at. If nil, then puts them back where they
  #      came from [FXPoint].
  #
  public
  def paste(at = nil)
    toPaste = Array.new

    @items.each do |hotspot|
      newHotspot = Hotspot.new(hotspot)

      if at
        newHotspot.offset! at.x - @copiedAt.x, at.y - @copiedAt.y
      end
 
      toPaste.push newHotspot
    end
   
    return toPaste
  end # paste()

  #####
  # Is there anything on the clipboard?
  #
  public
  def empty?
    @items.empty?
  end

end # class ClipBoard