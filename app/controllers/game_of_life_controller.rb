class GameOfLifeController < ApplicationController
  def index
    # Initialize session variables if they are not set
    session[:generation] ||= 0
    session[:grid_size] ||= { 'rows' => 0, 'cols' => 0 }
    session[:grid] ||= []
  end

 def load_file
   uploaded_file = params[:generation_file]

   if uploaded_file
     # Read the file and split lines into an array of characters
     parsed_grid = File.read(uploaded_file.tempfile).lines.map do |line|
       line.chomp.strip.chars  # Strip whitespace and convert to characters
     end.select { |line| line.all? { |char| char == '*' || char == '.' } } # Only keep valid grid lines

     # Log the parsed grid for debugging
     Rails.logger.info "Parsed Grid: #{parsed_grid.inspect}"

     if parsed_grid.empty?
       Rails.logger.error "Parsed grid is empty or invalid"
       return redirect_to root_path, alert: 'Invalid grid format in file.'
     end
 # Înlocuiește simbolurile
     parsed_grid.map! do |row|
       row.map! do |cell|
         case cell
         when '*'
           '🌳'  # Celul vie
         when '.'
           '🌑'  # Celul moarte
         else
           cell  # Păstrează celulele neidentificate
         end
       end
     end

     parsed_grid_size = { 'rows' => parsed_grid.length, 'cols' => parsed_grid.first.length }

     Rails.logger.info "Parsed Grid Size: #{parsed_grid_size.inspect}"

     # Store grid and size in the session
     session[:grid] = parsed_grid
     session[:grid_size] = parsed_grid_size
     session[:generation] = 0  # Reset generation count
   else
     Rails.logger.error "No file uploaded"
   end

   redirect_to root_path  # Redirect to index to refresh the grid display
 end


  def calculate_next_generation
    # Log incoming parameters for debugging
    Rails.logger.info "Params received: #{params.inspect}"

    # Parse grid and gridSize parameters from session
    grid = session[:grid]
    grid_size = session[:grid_size]

    # Debug logging to check grid and grid_size values
    Rails.logger.info "Grid: #{grid.inspect}"
    Rails.logger.info "Grid Size: #{grid_size.inspect}"

    # Ensure grid and grid_size are valid before proceeding
    if grid.nil? || grid_size.nil? || grid_size['rows'].nil? || grid_size['cols'].nil?
      Rails.logger.error "Invalid grid or grid_size parameters"
      return render json: { error: 'Invalid grid or grid size' }, status: :unprocessable_entity
    end

    next_grid = get_next_generation(grid, grid_size)

    # Update session with the new generation and grid
    session[:generation] += 1
    session[:grid] = next_grid

    # Redirect to the index action to refresh the page
    redirect_to root_path
  end

  private

def get_next_generation(grid, grid_size)
  new_grid = Array.new(grid_size['rows']) { Array.new(grid_size['cols'], '🌑') }

  (0...grid_size['rows']).each do |row|
    (0...grid_size['cols']).each do |col|
      live_neighbors = count_live_neighbors(grid, row, col, grid_size)

      if grid[row][col] == '🌳'  # Current cell is alive
        new_grid[row][col] = '🌳' if live_neighbors.between?(2, 3)  # Stay alive
      else  # Current cell is dead
        new_grid[row][col] = '🌳' if live_neighbors == 3  # Become alive
      end
    end
  end

  new_grid
end

def count_live_neighbors(grid, row, col, grid_size)
  directions = [-1, 0, 1].product([-1, 0, 1]) - [[0, 0]] # Get all neighbors excluding the cell itself
  live_count = 0

  directions.each do |dx, dy|
    new_row = row + dx
    new_col = col + dy
    if new_row.between?(0, grid_size['rows'] - 1) && new_col.between?(0, grid_size['cols'] - 1)
      live_count += 1 if grid[new_row][new_col] == '🌳'
    end
  end

  live_count
end

end
