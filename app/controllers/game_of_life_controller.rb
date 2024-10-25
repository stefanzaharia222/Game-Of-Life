class GameOfLifeController < ApplicationController
  def index
    puts "Rendering index template"

    # Retrieve session data if available
    generation = session[:generation] || 0
    grid_size = session[:grid_size] || { rows: 0, cols: 0 }
    grid = session[:grid] || []

    render 'game_of_life/index', locals: {
      generation: generation,
      grid_size: grid_size,
      grid: grid
    }
  end

  def load_file
    file = params[:generation_file]
    Rails.logger.info "File received: #{file.inspect}"
    if file.nil? || file.size.zero?
      Rails.logger.error "No file was uploaded."
      redirect_to action: :index, alert: "No file was uploaded."
      return
    end

    content = file.read
    generation, grid_size, grid = parse_file(content)

    puts "Loaded generation: #{generation}"
    puts "Grid size: #{grid_size}"
    puts "Grid: #{grid.inspect}"

    # Store the loaded data in the session
    session[:generation] = generation
    session[:grid_size] = grid_size
    session[:grid] = grid

    # Respond with Turbo Stream
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.replace('game_of_life', partial: 'game_of_life/index', locals: {
            generation: generation,
            grid_size: grid_size,
            grid: grid
          })
        ]
      }
      format.html { redirect_to action: :index }
    end
  end

def calculate_next_generation
  # Log incoming parameters for debugging
  Rails.logger.info "Params received: #{params.inspect}"

  # Parse grid and gridSize parameters
  grid = JSON.parse(params[:grid])
  grid_size = JSON.parse(params[:gridSize])

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
  session[:generation] = params[:generation].to_i + 1
  session[:grid_size] = grid_size
  session[:grid] = next_grid

  render 'game_of_life/index', locals: {
    generation: session[:generation],
    grid_size: grid_size,
    grid: next_grid
  }
end



  private

  def parse_file(content)
    lines = content.strip.split("\n")
    generation = lines[0].split[1].to_i
    rows, cols = lines[1].split.map(&:to_i)
    grid_size = { rows: rows, cols: cols }

    grid = lines[2..-1].map { |line| line.strip.chars }
    [generation, grid_size, grid]
  end

  def get_next_generation(grid, grid_size)
    rows = grid_size['rows']
    cols = grid_size['cols']
    next_grid = Array.new(rows) { Array.new(cols, '.') }

    (0...rows).each do |row|
      (0...cols).each do |col|
        alive_neighbors = count_alive_neighbors(grid, row, col, grid_size)
        current_cell = grid[row][col]

        Rails.logger.info "Processing cell [#{row}, #{col}]: #{current_cell}, Alive neighbors: #{alive_neighbors}"

        # Apply Game of Life rules
        if current_cell == '*'
          if alive_neighbors < 2 || alive_neighbors > 3
            next_grid[row][col] = '.'
          else
            next_grid[row][col] = '*'
          end
        else
          next_grid[row][col] = '*' if alive_neighbors == 3
        end
      end
    end

    Rails.logger.info "Next grid: #{next_grid.inspect}"
    next_grid
  end


def count_alive_neighbors(grid, row, col, grid_size)
  alive_neighbors = 0

  rows = grid_size['rows']
  cols = grid_size['cols']

  (-1..1).each do |i|
    (-1..1).each do |j|
      next if i == 0 && j == 0

      new_row = row + i
      new_col = col + j

      # Check boundaries using the parsed values
      if new_row.between?(0, rows - 1) && new_col.between?(0, cols - 1)
        alive_neighbors += 1 if grid[new_row][new_col] == '*'
      end
    end
  end
  alive_neighbors
end

end