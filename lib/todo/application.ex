defmodule Todo.Application do
  require Logger
  use Application
  
  @impl Application
  def start(_, _) do
    Logger.info("Starting application")
    Todo.System.start_link
  end
end
