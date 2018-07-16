defmodule GenstageImporterWeb.PageController do
  use GenstageImporterWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
