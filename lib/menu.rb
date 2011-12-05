###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Modules::     Menu
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################

require 'yaml'

require 'fox16'
include Fox

###############################################################################
# === Verification
# +VERIFY_ACCEL_UNIQUE+:: Verify that accelerator keys within a pane are unique.
# +VERIFY_RADIO+::        Verify that one and only one radio button is initially
#                         selected.
# +VERIFY_ALL+::          [= VERIFY_ACCEL_UNIQUE | VERIFY_RADIO]
#
module Menu
  # :stopdoc:
  KEY_TEXT     = 'text'
  KEY_IDENT    = 'ident'
  KEY_ITEMS    = 'items'

  bit = 0b1
  VERIFY_ACCEL_UNIQUE = bit
  VERIFY_RADIO        = (bit <<= 1)
  VERIFY_ALL          = VERIFY_ACCEL_UNIQUE | VERIFY_RADIO
  # :startdoc:

  #############################################################################
  # Mixin module to check for repeated accelerator keys.
  #
  module RepeatedAccel
    # See whether accelerator keys are repeated.
    #
    # Returns: array
    private
    def repeatedAccel(items)
      accels = Hash.new
      repeated = Array.new

      # Go through each item and see if its accelerator key has already been
      # used within the items list.
      items.each do |item|
        if item[KEY_TEXT] =~ /&(.)/
          key = $1.downcase
          if accels[key]
            repeated.push key # Accelerator has been repeated.
          else
            accels[key] = true
          end
        end
      end

      if repeated.size > 0
        repeated
      else
        nil
      end
    end
  end # module LoadYaml
  
  #############################################################################
  #
  # An FXRuby (1.2) menu generator that uses YAML markup to describe menus.
  #
  class MenuBar < FXMenuBar
    include RepeatedAccel
  
    #
    # Creates a new MenuBar.
    #
    # === Parameters
    # +parent+:: Parent window [FX???]
    # +source+:: YAML file to load [IO]
    #            OR YAML data to parse [String]
    #            OR MenuBar data structure [Array]
    # +target+:: Target of any menu item actions [FX???]
    # +opts+::   Options [FixNum]
    #
    private
    def initialize(parent, source, target, opts = VERIFY_ALL)
      super parent
  
      @titles = Hash.new # Contains panes.
  
      # Parse the markup file.
      structure =
        case source
          when String, IO
            YAML::load source
          when Array
            source
          else
            raise ArgumentError
          end
  
      if (opts & VERIFY_ACCEL_UNIQUE) != 0
        # Check for repeated accelerators within the menu bar.
        repeated = repeatedAccel(structure)
        if repeated
          raise "Accelerator not unique for '#{repeated.join "', '"}'"
        end
      end

      # Create each of the menu panes on the main menu bar.
      structure.each do |titleStruct| # Menu drop-down pane.
        @titles[titleStruct[KEY_IDENT]] =
            MenuTitle.new self, titleStruct, target, opts
      end
  
    end # initialize()
  
    #
    # Allow access to titles within the MenuBar and thus deeper into the menu.
    # * <tt> menuBar[:file].pane[:open].enabled = false </tt>
    # * <tt> menuBar[:mode].pane[:colourCascade].pane[:blue].check = true </tt>
    #
    # === Parameters
    # +ident+:: The symbolic name for the the pane we want to look at. [Symbol]
    #
    public
    def [](ident)
      @titles[ident]
    end # []()
  end # MenuBar
  

  #############################################################################
  #
  #
  class MenuTitle < FXMenuTitle

    #
    # Creates a new MenuTitle.
    #
    # === Parameters
    # +parent+:: Parent window [FX???]
    # +source+:: YAML file to load [IO]
    #            OR YAML data to parse [String]
    #            OR MenuTitle data structure [Hash]
    # +target+:: Target of any menu item actions [FX???]
    # +opts+::   Options [FixNum]
    #
    private
    def initialize(parent, source, target, opts = VERIFY_ALL)

      # Parse the markup file.
      structure =
        case source
        when String, IO
          YAML::load source
        when Hash
          source
        else
          raise ArgumentError
        end

      if structure[KEY_ITEMS]
        pane = MenuPane.new parent, structure[KEY_ITEMS], target, opts
      end 

      super parent, structure[KEY_TEXT], nil, pane
    end # initialize()

  end # MenuTitle

  #############################################################################
  #
  #
  class MenuPane < FXMenuPane
    include RepeatedAccel

    # :stopdoc:
    KEY_METHOD     = 'method'
    KEY_CHECKED    = 'checked'  # For check buttons.
    KEY_SELECTED   = 'selected' # For radio buttons.
    KEY_SHORTCUT   = 'shortcut'
    KEY_STATUS     = 'status'
    KEY_DISABLED   = 'disabled'
    KEY_GROUP      = 'group'    # For radio buttons.
    KEY_TYPE       = 'type'

    # Enumeration of the KEY_TYPE
    TYPE_RADIO     = 'radio'
    TYPE_COMMAND   = 'command'
    TYPE_CASCADE   = 'cascade'
    TYPE_SEPARATOR = 'separator'
    TYPE_CHECK     = 'check'
    # :startdoc:

    attr_reader :radioGroups

    #
    # Creates a new MenuPane.
    #
    # === Parameters
    # +parent+:: Parent window [FX???]
    # +source+:: YAML file to load [IO]
    #            OR YAML data to parse [String]
    #            OR MenuPane data structure [Array]
    # +target+:: Target of any menu item actions [FX???]
    # +opts+::   Options [FixNum]
    #
    private
    def initialize(parent, source, target, opts = VERIFY_ALL)
      super parent

      # Parse the markup file.
      structure =
        case source
        when String, IO
          YAML::load source
        when Array
          source
        else
          raise ArgumentError, "Faulty source (#{source.class} in #{self.inspect}"
        end

      if (opts & VERIFY_ACCEL_UNIQUE) != 0
        # Check for repeated accelerators within the panel.
          repeated = repeatedAccel(structure)
        if repeated
          raise "Accelerator not unique for '#{repeated.join "', '"}'"
        end
      end

      @items = Hash.new
      @radioGroups = Hash.new
     
      # Create each item on the pane.
      structure.each do |itemStruct|

        text = "#{itemStruct[KEY_TEXT]}\t" +
               "#{itemStruct[KEY_SHORTCUT]}\t" +
               "#{itemStruct[KEY_STATUS]}"
  
        # Create the specific menu item.
        case itemStruct[KEY_TYPE]
        when TYPE_COMMAND
          command = FXMenuCommand.new self, text
  
        when TYPE_CHECK
          command = FXMenuCheck.new self, text
  
          case itemStruct[KEY_CHECKED]
          when true, false
            command.check = itemStruct[KEY_CHECKED]
          else
            command.check = MAYBE
          end
  
        when TYPE_RADIO
          # If it doesn't already exist, create a new radio-button group.
          group = @radioGroups[itemStruct[KEY_GROUP]]
          unless group
            if itemStruct[KEY_METHOD] &&
               target.respond_to?(itemStruct[KEY_METHOD], true)

              group = RadioGroup.new target.method(itemStruct[KEY_METHOD])
            else
              raise NameError, "Method #{itemStruct[KEY_METHOD]}(sender, sel, event) " +
                               "not found on #{target}"
            end
            @radioGroups[itemStruct[KEY_GROUP]] = group
          end
  
          # Add radio button to group. The data target will be added later.
          command = FXMenuRadio.new self, text

          group.add command, (itemStruct[KEY_SELECTED] == true)
  
        when TYPE_SEPARATOR
          command = FXMenuSeparator.new self
  
        when TYPE_CASCADE
          command = MenuCascade.new self, itemStruct, target
  
        else
          raise "Unknown menu item type #{itemY[KEY_TYPE]}"
        end
    
        # Record the menu command in the command tree if there is a need.
        if itemStruct[KEY_IDENT]
          @items[itemStruct[KEY_IDENT]] = command
        end
  
        # Connect a given method (radio buttons already connected).
        if itemStruct[KEY_METHOD] && (itemStruct[KEY_TYPE] != TYPE_RADIO)
          if target.respond_to? itemStruct[KEY_METHOD], true
            command.connect SEL_COMMAND, target.method(itemStruct[KEY_METHOD])
  
          else
            raise NameError, "Method #{itemStruct[KEY_METHOD]}(sender, sel, event) " +
                             "not found on #{target}"
          end
        end
  
        # We assume commands are enabled by default.
        command.disable if itemStruct[KEY_DISABLED]
      end
  
    end # addItems()

  
    #
    # Access to the items within the MenuPane. e.g.
    # * <tt> menuPane[:open].enabled = false </tt>
    #
    # === Parameters
    # +ident+:: The root menu pane to start navigating from. [Symbol]
    # Returns:: Item named ident.
    #
    public
    def [](ident)
      @items[ident]
    end # []()
  end # MenuPane


  #############################################################################
  #
  #
  class MenuCascade < FXMenuCascade

    #
    # Creates a new MenuCascade.
    #
    # === Parameters
    # +parent+:: Parent window [FX???]
    # +source+:: YAML file to load [IO]
    #            OR YAML data to parse [String]
    #            OR MenuBar data structure [Hash]
    # +target+:: Target of any menu item actions [FX???]
    # +opts+::   Options [FixNum]
    #
    private
    def initialize(parent, source, target, opts = VERIFY_ALL)
      structure =
        case source
        when String, IO
          YAML::load source
        when Hash
          source
        else
          raise ArgumentError,
                "Faulty source (#{source.class} in #{self.inspect}"
        end

      pane = MenuPane.new parent, structure[KEY_ITEMS], target, opts

      super parent, structure[KEY_TEXT], nil, pane
    end
  end # class MenuCascade


  #############################################################################
  #
  #
  class RadioGroup
    attr_reader :radios # Array of FXMenuRadio or FXRadioButton
    attr_reader :target

    # :stopdoc:
    TARGET_INIT = nil
    # :startdoc:

    #
    #
    #
    private
    def initialize(method)
      @target = FXDataTarget.new TARGET_INIT
      @target.connect SEL_COMMAND, method
      @radios = Array.new
    end

    #
    #
    #
    public
    def add(radio, checked)
      radioNum = @radios.size

      @radios.push radio

      radio.selector = (FXDataTarget::ID_OPTION + radioNum)
      radio.target = @target

      if checked
        if @target.value == TARGET_INIT
          @target.value = radioNum
        else
          raise "More than one radio button selected!"
        end
      end
         
      return radio
    end

    #
    # Returns: Selected radio item.
    #
    public
    def selected()
      if @target.value == TARGET_INIT
        nil
      else 
        @radios[@target.value]
      end
    end
  end # class RadioGroup


  #############################################################################
  #
  # A popup menu pane.
  #
  class PopupMenu < MenuPane

    #
    # Runs the PopupMenu modally.
    #
    public
    def runModal(x, y)
      popup nil, x, y
      app.runModalWhileShown self
    end
    
  end # class PopupMenu

end # module Menu


###
# Radio button group
# class RadioGroupBox < FXGroupBox
#   
#   private
#   def initalize(*args)
#     super

#     @group = RadioGroup.new
#   end

#   public
#   def addRadioButton(radio)
#     @group.add radio
#   end

#   public
#   def selected
#     @group.value
#   end

#   public
#   def selectedRadio
#     @group.radios[@group.value]
#   end
# end