###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Module::      PathFinding
# Classes::     Path, TreeNode, GridNode, OpenList
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################

module PathFinding

  #############################################################################
  # Stores an inclusive path of GridNode objects and records the overall travel
  # distance.
  #
  class Path < Array
    attr_reader :distance
  
    #
    #
    private
    def initialize(nodes, distance)
      super nodes
      @distance = distance
    end
  end # Path

  #############################################################################
  #
  #
  #
  class TreeNode
    attr_reader :parent, :gridNode, :distSoFar, :estDistToGo
  
    #
    #
    # === Parameters
    # +parent+::      Parent node to become the child of [TreeNode]
    # +gridNode+::    Owned node [GridNode]
    # +estDistToGo+:: Estimated (minimum) distance to destination [Fixnum]
    #
    private
    def initialize(parent, gridNode, estDistToGo)
      @parent, @gridNode, @estDistToGo =
          parent, gridNode, estDistToGo
  
      if @parent
        @parent.addChild self
      end

      recalcDistSoFar
  
      @children = Array.new
    end

  
    #
    # 
    # === Parameters
    # +child+:: Node to add to list of children [TreeNode]
    #
    public
    def addChild(child)
      @children.push child
    end
  
    #
    # === Parameters
    # +child+:: Node to remove from list of children [TreeNode]
    #
    public
    def removeChild(child)
      @children.delete child
    end
  
    #
    #
    #
    # === Paramters
    # +parent+::    New parent for the shorter path.
    #
    public
    def relocate(newParent)
  
      # Remove link to our old parent.
      @parent.removeChild self if @parent
 
      @parent = newParent

      recalcDistSoFar # It should have been reduced.

      # Introduce ourself to new parent.
      @parent.addChild self if @parent
  
      self
    end # relocate()

    #
    # Recalculate distance so far.
    #
    private
    def recalcDistSoFar()
      if @parent
        @distSoFar = @gridNode.entryCost + @parent.distSoFar
      else # Root node
        @distSoFar = 0
      end
    end

    #
    # Construct the path required to get to @gridNode.
    #
    public
    def path()
      if @parent
        @parent.path + [ @gridNode ]
      else 
        [ @gridNode ]
      end
    end # path()
  
    #
    #
    #
    public 
    def estTotalDist()
      distSoFar + @estDistToGo
    end
  end # class TreeNode
  
  #############################################################################
  #
  #
  #
  class GridNode
    DEBUG_MODE = false

    attr_reader   :entryCost
    attr_reader   :x
    attr_reader   :y
    attr_accessor :exits
  
    #
    #
    #
    private
    def initialize(entryCost, x, y)
      @entryCost, @x, @y = entryCost, x, y
      @exits = Array.new
    end
  
    #
    # Measure the minimum distance to target. Uses orthogonal stepped,
    # "Manhatten-style", movement.
    #
    # === Parameters
    # +target+::  GridNode to measure distance to [GridNode]
    #
    public
    def distanceTo(target)
      (@x - target.x).abs + (@y - target.y).abs
    end
  
    #
    # Find the shortest route from one GridNode to another using a standard
    # A* pathfinding algorithm.
    #
    # === Parameters
    # +start+::  Initial GridNode to measure path from. [GridNode]
    # +finish+:: Target GridNode to find path to. [GridNode]
    # +limit+::  Maximum distance to travel searching for a path. [Fixnum:nil]
    # Returns::  Shortest Path from +start+ to +finish+, [Path]
    #            OR (if no path was found within the limit)
    #            nil
    #
    public
    def shortestPath(finish, limit = nil)
      open = OpenList.new
      closed = Array.new

      # The start position is the root node.
      treeNode = TreeNode.new nil, self, distanceTo(finish)
  
      until treeNode.nil? || treeNode.gridNode == finish
        puts "Checking adjacent to: #{treeNode.gridNode}" if DEBUG_MODE

        treeNode.gridNode.exits.each do |adjGn|
          unless closed.index adjGn
            distToAdjGn = treeNode.distSoFar + adjGn.entryCost
  
            # If a limit has been set, and surpassed, ignore this node.
            unless limit && (distToAdjGn > limit)
              # See if node has already been examined.
              openTNode = open.find { |o| o.gridNode == adjGn }
              if openTNode # Found in open list.

                # Replace the old path if this one is shorter.
                if distToAdjGn < openTNode.distSoFar
                  replaced = openTNode.relocate treeNode
                  open.sort! # Distances will have changed!
                  
                  puts "Replaced: #{adjGn}" if DEBUG_MODE
                end
  
              elsif closed.index(adjGn).nil? # Not in closed list.
                open.insert TreeNode.new(treeNode, adjGn,
                                         adjGn.distanceTo(finish))
              end
            end
          end
        end

        # Add the current node to the closed list, now it is finished with.
        closed.push treeNode.gridNode
  
        puts "Open: #{open.collect { |n| "#{n.gridNode} (#{n.distSoFar}+#{n.estDistToGo})"}.join ", "}" +
             " | Closed: #{closed.join ", "}" if DEBUG_MODE
  
        # Pull the next possible position off the list.
        treeNode = open.shift
      end 

      if treeNode
        Path.new treeNode.path, treeNode.distSoFar
      else
        nil
      end
    end # shortestPath()

    #
    # List of paths of a given length spreading out from this position.
    #
    # === Parameters
    # +distance+:: Distance of paths to collect.
    #
    public
    def absolutePaths(distance)
      findPaths(distance, false)
    end
  
    #
    # All paths from self, up to a maximum distance of +limit+.
    #
    # === Parameters
    # +limit+:: Maximum distance of paths to collect. If nil, then the paths to
    #           every node in the graph will be computed [Fixnum:nil]
    #
    public
    def allPaths(limit = nil)
      findPaths(limit, true)
    end

    #
    #
    private
    def findPaths(limit, getAll)
      open = OpenList.new
      closed = Array.new
      paths = Array.new

      # The start position is the root node.
      treeNode = TreeNode.new nil, self, 0
  
      until treeNode.nil?
        puts "Checking adjacent to: #{treeNode.gridNode}" if DEBUG_MODE

        treeNode.gridNode.exits.each do |adjGn|
          unless closed.index adjGn
            distToAdjGn = treeNode.distSoFar + adjGn.entryCost
  
            # If a limit has been set, and surpassed, give up.
            break if limit && (distToAdjGn > limit)

            # See if node has already been examined.
            openTNode = open.find { |o| o.gridNode == adjGn }
            if openTNode # Found in open list.

              # Replace the old path if this one is shorter.
              if distToAdjGn < openTNode.distSoFar
                openTNode.relocate treeNode, distToAdjGn
                open.sort! # Distances will have changed!
                
                puts "Replaced: #{adjGn}" if DEBUG_MODE
              end

            elsif closed.index(adjGn).nil? # Not in closed list.
              open.insert TreeNode.new(treeNode, adjGn, 0)
            end
          end
        end

        # Add the current node to the closed list, now it is finished with.
        closed.push treeNode.gridNode

        # Store the path to the current node.
        if (treeNode.distSoFar > 0) && (getAll ||  (treeNode.distSoFar == limit))
          paths.push Path.new(treeNode.path, treeNode.distSoFar)
        end
  
        puts "Open: #{open.collect { |n| "#{n.gridNode} (#{n.distSoFar}+#{n.estDistToGo})"}.join ", "}" +
             " | Closed: #{closed.join ", "}" if DEBUG_MODE
  
        # Pull the next possible position off the list.
        treeNode = open.shift
      end 

      if paths.size > 0
        paths
      else
        nil
      end
      
    end

  end # class GridNode
  
  #############################################################################
  #
  # A list of open nodes used when creating a pathfinding tree. The nodes are
  # ordered by estimated total distance.
  #
  class OpenList < Array
    #
    # ===Parameters
    # +treeNode+:: TreeNode to insert into the open list.
    # Returns:: +treeNode+
    #
    public
    def insert(treeNode)
      # Find a node which is at least as large as treeNode.
      longer = find { |n| n.estTotalDist >= treeNode.estTotalDist }
      if longer
        longerPos = rindex longer # *Probably* near the end.
        self[longerPos, 0] = treeNode # Insert before the longer one.
      else # Must be longer distance, so place at end.
        push treeNode
      end
      
      treeNode
    end # insert()

    #
    # May need resorting if any distances have been recalculated.
    #
    public
    def sort!()
      super { |a, b| a.estTotalDist <=> b.estTotalDist }
    end
  end # class OpenList

end # module PathFinding